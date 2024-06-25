use crate::error::{Error, ReadError, RemoteError};
use crate::parser::{Call, MessageReader, RequestId};
use crate::plugin::RpcCtx;
use crate::rpc_peer::{RawPeer, Response, RpcState};
use serde::de::{DeserializeOwned, Error as SerdeError};
use serde_json::Value;

use std::io::{BufRead, Write};

use std::sync::Arc;
use std::thread;
use std::time::Duration;
use tracing::{error, trace};

const MAX_IDLE_WAIT: Duration = Duration::from_millis(5);
#[derive(Debug, Clone)]
pub struct RpcObject(pub Value);

impl RpcObject {
  /// Returns the 'id' of the underlying object, if present.
  pub fn get_id(&self) -> Option<RequestId> {
    self.0.get("id").and_then(Value::as_u64)
  }

  /// Returns the 'method' field of the underlying object, if present.
  pub fn get_method(&self) -> Option<&str> {
    self.0.get("method").and_then(Value::as_str)
  }

  /// Returns `true` if this object looks like an RPC response;
  /// that is, if it has an 'id' field and does _not_ have a 'method'
  /// field.
  pub fn is_response(&self) -> bool {
    self.0.get("id").is_some() && self.0.get("method").is_none()
  }

  /// Converts the underlying `Value` into an RPC response object.
  /// The caller should verify that the object is a response before calling this method.
  /// # Errors
  /// If the `Value` is not a well-formed response object, this returns a `String` containing an
  /// error message. The caller should print this message and exit.
  pub fn into_response(mut self) -> Result<Response, String> {
    let _ = self
      .get_id()
      .ok_or("Response requires 'id' field.".to_string())?;

    if self.0.get("result").is_some() == self.0.get("error").is_some() {
      return Err("RPC response must contain exactly one of 'error' or 'result' fields.".into());
    }
    let result = self.0.as_object_mut().and_then(|obj| obj.remove("result"));

    match result {
      Some(r) => Ok(Ok(r)),
      None => {
        let error = self
          .0
          .as_object_mut()
          .and_then(|obj| obj.remove("error"))
          .unwrap();
        Err(format!("Error handling response: {:?}", error))
      },
    }
  }

  /// Converts the underlying `Value` into either an RPC notification or request.
  pub fn into_rpc<R>(self) -> Result<Call<R>, serde_json::Error>
  where
    R: DeserializeOwned,
  {
    let id = self.get_id();
    match id {
      Some(id) => match serde_json::from_value::<R>(self.0) {
        Ok(resp) => Ok(Call::Request(id, resp)),
        Err(err) => Ok(Call::InvalidRequest(id, err.into())),
      },
      None => match self.0.get("message").and_then(|value| value.as_str()) {
        None => Err(serde_json::Error::missing_field("message")),
        Some(s) => Ok(Call::Message(s.to_string().into())),
      },
    }
  }
}

impl From<Value> for RpcObject {
  fn from(v: Value) -> RpcObject {
    RpcObject(v)
  }
}

pub trait Handler {
  type Request: DeserializeOwned;
  fn handle_request(&mut self, ctx: &RpcCtx, rpc: Self::Request) -> Result<Value, RemoteError>;
  #[allow(unused_variables)]
  fn idle(&mut self, ctx: &RpcCtx, token: usize) {}
}

/// A helper type which shuts down the runloop if a panic occurs while
/// handling an RPC.
struct PanicGuard<'a, W: Write + 'static>(&'a RawPeer<W>);

impl<'a, W: Write + 'static> Drop for PanicGuard<'a, W> {
  fn drop(&mut self) {
    if thread::panicking() {
      error!("[RPC] panic guard hit, closing run loop");
      self.0.disconnect();
    }
  }
}

/// A structure holding the state of a main loop for handling RPC's.
pub struct RpcLoop<W: Write + 'static> {
  reader: MessageReader,
  peer: RawPeer<W>,
}

impl<W: Write + Send> RpcLoop<W> {
  /// Creates a new `RpcLoop` with the given output stream (which is used for
  /// sending requests and notifications, as well as responses).
  pub fn new(writer: W) -> Self {
    let rpc_peer = RawPeer(Arc::new(RpcState::new(writer)));
    RpcLoop {
      reader: MessageReader::default(),
      peer: rpc_peer,
    }
  }

  /// Gets a reference to the peer.
  pub fn get_raw_peer(&self) -> RawPeer<W> {
    self.peer.clone()
  }

  /// Starts the event loop, reading lines from the reader until EOF or an error occurs.
  ///
  /// Returns `Ok()` if EOF is reached, otherwise returns the underlying `ReadError`.
  ///
  /// # Note:
  /// The reader is provided via a closure to avoid needing `Send`. The main loop runs on a separate I/O thread that calls this closure at startup.
  /// Calls to the handler occur on the caller's thread and maintain the order from the channel. Currently, there can only be one outstanding incoming request.
  pub fn mainloop<R, BufferReadFn, H>(
    &mut self,
    plugin_name: &str,
    buffer_read_fn: BufferReadFn,
    handler: &mut H,
  ) -> Result<(), ReadError>
  where
    R: BufRead,
    BufferReadFn: Send + FnOnce() -> R,
    H: Handler,
  {
    let exit = crossbeam_utils::thread::scope(|scope| {
      let peer = self.get_raw_peer();
      peer.reset_needs_exit();

      let ctx = RpcCtx {
        peer: Box::new(peer.clone()),
      };

      // 1. Spawn a new thread for reading data from a stream.
      // 2. Continuously read data from the stream.
      // 3. Parse the data as JSON.
      // 4. Handle the JSON data as either a response or another type of JSON object.
      // 5. Manage errors and connection status.
      scope.spawn(move |_| {
        let mut stream = buffer_read_fn();
        loop {
          if self.peer.needs_exit() {
            trace!("read loop exit");
            break;
          }

          let json = match self.reader.next(&mut stream) {
            Ok(json) => json,
            Err(err) => {
              if self.peer.0.is_blocking() {
                self.peer.disconnect();
              }
              self.peer.put_rpc_object(Err(err));
              break;
            },
          };
          if json.is_response() {
            let id = json.get_id().unwrap();
            match json.into_response() {
              Ok(resp) => {
                let resp = resp.map_err(Error::from);
                self.peer.handle_response(id, resp);
              },
              Err(msg) => {
                error!("[RPC] failed to parse response: {}", msg);
                self.peer.handle_response(id, Err(Error::InvalidResponse));
              },
            }
          } else {
            self.peer.put_rpc_object(Ok(json));
          }
        }
      });

      loop {
        let _guard = PanicGuard(&peer);
        let read_result = next_read(&peer, handler, &ctx);
        let json = match read_result {
          Ok(json) => json,
          Err(err) => {
            // finish idle work before disconnecting;
            // this is mostly useful for integration tests.
            if let Some(idle_token) = peer.try_get_idle() {
              handler.idle(&ctx, idle_token);
            }
            peer.disconnect();
            return err;
          },
        };

        match json.into_rpc::<H::Request>() {
          Ok(Call::Request(id, cmd)) => {
            // Handle request sent from the client. For example from python executable.
            trace!("[RPC] received request: {}", id);
            let result = handler.handle_request(&ctx, cmd);
            peer.respond(result, id);
          },
          Ok(Call::InvalidRequest(id, err)) => {
            trace!("[RPC] received invalid request: {}", id);
            peer.respond(Err(err), id)
          },
          Err(err) => {
            error!("[RPC] error parsing message: {:?}", err);
            peer.disconnect();
            return ReadError::UnknownRequest(err);
          },
          Ok(Call::Message(msg)) => {
            trace!("[RPC {}]: {}", plugin_name, msg);
          },
        }
      }
    })
    .unwrap();

    if exit.is_disconnect() {
      Ok(())
    } else {
      Err(exit)
    }
  }
}

/// Returns the next read result, checking for idle work when no
/// result is available.
fn next_read<W, H>(peer: &RawPeer<W>, handler: &mut H, ctx: &RpcCtx) -> Result<RpcObject, ReadError>
where
  W: Write + Send,
  H: Handler,
{
  loop {
    if let Some(result) = peer.try_get_rx() {
      return result;
    }
    // handle timers before general idle work
    let time_to_next_timer = match peer.check_timers() {
      Some(Ok(token)) => {
        do_idle(handler, ctx, token);
        continue;
      },
      Some(Err(duration)) => Some(duration),
      None => None,
    };

    if let Some(idle_token) = peer.try_get_idle() {
      do_idle(handler, ctx, idle_token);
      continue;
    }

    // we don't want to block indefinitely if there's no current idle work,
    // because idle work could be scheduled from another thread.
    let idle_timeout = time_to_next_timer
      .unwrap_or(MAX_IDLE_WAIT)
      .min(MAX_IDLE_WAIT);

    if let Some(result) = peer.get_rx_timeout(idle_timeout) {
      return result;
    }
  }
}

fn do_idle<H: Handler>(_handler: &mut H, _ctx: &RpcCtx, _token: usize) {}
