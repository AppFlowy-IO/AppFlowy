use crate::core::plugin::{Callback, Peer, PluginId};
use crate::core::rpc_object::RpcObject;
use crate::error::{Error, ReadError, RemoteError};
use parking_lot::{Condvar, Mutex};
use serde::{de, ser, Deserialize, Deserializer, Serialize, Serializer};
use serde_json::{json, Value};
use std::collections::{BTreeMap, BinaryHeap, VecDeque};
use std::io::Write;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{mpsc, Arc};
use std::time::{Duration, Instant};
use std::{cmp, io};
use tracing::{error, trace, warn};

pub struct PluginCommand<T> {
  pub plugin_id: PluginId,
  pub cmd: T,
}

impl<T: Serialize> Serialize for PluginCommand<T> {
  fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
  where
    S: Serializer,
  {
    let mut v = serde_json::to_value(&self.cmd).map_err(ser::Error::custom)?;
    v["params"]["plugin_id"] = json!(self.plugin_id);
    v.serialize(serializer)
  }
}

impl<'de, T: Deserialize<'de>> Deserialize<'de> for PluginCommand<T> {
  fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
  where
    D: Deserializer<'de>,
  {
    #[derive(Deserialize)]
    struct PluginIdHelper {
      plugin_id: PluginId,
    }
    let v = Value::deserialize(deserializer)?;
    let plugin_id = PluginIdHelper::deserialize(&v)
      .map_err(de::Error::custom)?
      .plugin_id;
    let cmd = T::deserialize(v).map_err(de::Error::custom)?;
    Ok(PluginCommand { plugin_id, cmd })
  }
}

pub struct RpcState<W: Write> {
  rx_queue: Mutex<VecDeque<Result<RpcObject, ReadError>>>,
  rx_cvar: Condvar,
  writer: Mutex<W>,
  id: AtomicUsize,
  pending: Mutex<BTreeMap<usize, ResponseHandler>>,
  timers: Mutex<BinaryHeap<Timer>>,
  needs_exit: AtomicBool,
  is_blocking: AtomicBool,
}

impl<W: Write> RpcState<W> {
  pub fn new(writer: W) -> Self {
    RpcState {
      rx_queue: Mutex::new(VecDeque::new()),
      rx_cvar: Condvar::new(),
      writer: Mutex::new(writer),
      id: AtomicUsize::new(0),
      pending: Mutex::new(BTreeMap::new()),
      timers: Mutex::new(BinaryHeap::new()),
      needs_exit: AtomicBool::new(false),
      is_blocking: Default::default(),
    }
  }

  pub fn is_blocking(&self) -> bool {
    self.is_blocking.load(Ordering::Acquire)
  }
}

pub struct RawPeer<W: Write + 'static>(pub(crate) Arc<RpcState<W>>);

impl<W: Write + Send + 'static> Peer for RawPeer<W> {
  fn box_clone(&self) -> Arc<dyn Peer> {
    Arc::new((*self).clone())
  }
  fn send_rpc_notification(&self, method: &str, params: &Value) {
    if let Err(e) = self.send(&json!({
        "method": method,
        "params": params,
    })) {
      error!(
        "send error on send_rpc_notification method {}: {}",
        method, e
      );
    }
  }

  fn send_rpc_request_async(&self, method: &str, params: &Value, f: Box<dyn Callback>) {
    self.send_rpc(method, params, ResponseHandler::Callback(f));
  }

  fn send_rpc_request(&self, method: &str, params: &Value) -> Result<Value, Error> {
    let (tx, rx) = mpsc::channel();
    self.0.is_blocking.store(true, Ordering::Release);
    self.send_rpc(method, params, ResponseHandler::Chan(tx));
    rx.recv().unwrap_or(Err(Error::PeerDisconnect))
  }

  fn request_is_pending(&self) -> bool {
    let queue = self.0.rx_queue.lock();
    !queue.is_empty()
  }

  fn schedule_timer(&self, after: Instant, token: usize) {
    self.0.timers.lock().push(Timer {
      fire_after: after,
      token,
    });
  }
}

impl<W: Write> RawPeer<W> {
  fn send(&self, v: &Value) -> Result<(), io::Error> {
    let mut s = serde_json::to_string(v).unwrap();
    s.push('\n');
    self.0.writer.lock().write_all(s.as_bytes())
  }

  pub(crate) fn respond(&self, result: Response, id: u64) {
    let mut response = json!({ "id": id });
    match result {
      Ok(result) => response["result"] = result,
      Err(error) => response["error"] = json!(error),
    };
    if let Err(e) = self.send(&response) {
      error!("[RPC] error {} sending response to RPC {:?}", e, id);
    }
  }

  fn send_rpc(&self, method: &str, params: &Value, rh: ResponseHandler) {
    trace!("[RPC] call method: {} params: {:?}", method, params);
    let id = self.0.id.fetch_add(1, Ordering::Relaxed);
    {
      let mut pending = self.0.pending.lock();
      pending.insert(id, rh);
    }

    // Call the ResponseHandler if the send fails. Otherwise, the response will be
    // called in handle_response.
    if let Err(e) = self.send(&json!({
        "id": id,
        "method": method,
        "params": params,
    })) {
      let mut pending = self.0.pending.lock();
      if let Some(rh) = pending.remove(&id) {
        rh.invoke(Err(Error::Io(e)));
      }
    }
  }

  pub(crate) fn handle_response(&self, id: u64, resp: Result<Value, Error>) {
    let id = id as usize;
    let handler = {
      let mut pending = self.0.pending.lock();
      pending.remove(&id)
    };
    match handler {
      Some(response_handler) => {
        //
        response_handler.invoke(resp)
      },
      None => warn!("[RPC] id {} not found in pending", id),
    }
  }

  /// Get a message from the receive queue if available.
  pub(crate) fn try_get_rx(&self) -> Option<Result<RpcObject, ReadError>> {
    let mut queue = self.0.rx_queue.lock();
    queue.pop_front()
  }

  /// Get a message from the receive queue, waiting for at most `Duration`
  /// and returning `None` if no message is available.
  pub(crate) fn get_rx_timeout(&self, dur: Duration) -> Option<Result<RpcObject, ReadError>> {
    let mut queue = self.0.rx_queue.lock();
    let result = self.0.rx_cvar.wait_for(&mut queue, dur);
    if result.timed_out() {
      return None;
    }
    queue.pop_front()
  }

  /// Adds a message to the receive queue. The message should only
  /// be `None` if the read thread is exiting.
  pub(crate) fn put_rpc_object(&self, json: Result<RpcObject, ReadError>) {
    let mut queue = self.0.rx_queue.lock();
    queue.push_back(json);
    self.0.rx_cvar.notify_one();
  }

  /// Checks the status of the most imminent timer.
  ///
  /// If the timer has expired, returns `Some(Ok(_))` with the corresponding token.
  /// If a timer exists but has not expired, returns `Some(Err(_))` with the `Duration` until the timer is ready.
  /// Returns `None` if no timers are registered.
  ///
  /// # Returns
  /// - `Some(Ok(usize))`: If the timer has expired, with the corresponding token.
  /// - `Some(Err(Duration))`: If a timer exists but hasn't expired, with the time remaining until it is ready.
  /// - `None`: If no timers are registered.
  pub(crate) fn check_timers(&self) -> Option<Result<usize, Duration>> {
    let mut timers = self.0.timers.lock();
    match timers.peek() {
      None => return None,
      Some(t) => {
        let now = Instant::now();
        if t.fire_after > now {
          return Some(Err(t.fire_after - now));
        }
      },
    }
    Some(Ok(timers.pop().unwrap().token))
  }

  /// send disconnect error to pending requests.
  pub(crate) fn disconnect(&self) {
    trace!("[RPC] disconnecting peer");
    let mut pending = self.0.pending.lock();
    let ids = pending.keys().cloned().collect::<Vec<_>>();
    for id in &ids {
      let callback = pending.remove(id).unwrap();
      callback.invoke(Err(Error::PeerDisconnect));
    }
    self.0.needs_exit.store(true, Ordering::Relaxed);
  }

  /// Returns `true` if an error has occured in the main thread.
  pub(crate) fn needs_exit(&self) -> bool {
    self.0.needs_exit.load(Ordering::Relaxed)
  }

  pub(crate) fn reset_needs_exit(&self) {
    self.0.needs_exit.store(false, Ordering::SeqCst);
  }
}

impl<W: Write> Clone for RawPeer<W> {
  fn clone(&self) -> Self {
    RawPeer(self.0.clone())
  }
}

pub struct ResponsePayload {
  value: Value,
}

pub type Response = Result<Value, RemoteError>;
enum ResponseHandler {
  Chan(mpsc::Sender<Result<Value, Error>>),
  Callback(Box<dyn Callback>),
}

impl ResponseHandler {
  fn invoke(self, result: Result<Value, Error>) {
    match self {
      ResponseHandler::Chan(tx) => {
        let _ = tx.send(result);
      },
      ResponseHandler::Callback(f) => f.call(result),
    }
  }
}
#[derive(Debug, PartialEq, Eq)]
struct Timer {
  fire_after: Instant,
  token: usize,
}

impl Ord for Timer {
  fn cmp(&self, other: &Timer) -> cmp::Ordering {
    other.fire_after.cmp(&self.fire_after)
  }
}

impl PartialOrd for Timer {
  fn partial_cmp(&self, other: &Timer) -> Option<cmp::Ordering> {
    Some(self.cmp(other))
  }
}
