use crate::core::parser::{Call, MessageReader};
use crate::core::plugin::RpcCtx;
use crate::core::rpc_object::RpcObject;
use crate::core::rpc_peer::{RawPeer, ResponsePayload, RpcState};
use crate::error::{ReadError, RemoteError, SidecarError};
use serde::de::DeserializeOwned;

use std::io::{BufRead, Write};
use std::sync::Arc;
use std::thread;
use std::time::Duration;
use tracing::{error, info, trace};

const MAX_IDLE_WAIT: Duration = Duration::from_millis(5);

pub trait Handler {
  type Request: DeserializeOwned;
  fn handle_request(
    &mut self,
    ctx: &RpcCtx,
    rpc: Self::Request,
  ) -> Result<ResponsePayload, RemoteError>;
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
        peer: Arc::new(peer.clone()),
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
            let request_id = json.get_id().unwrap();
            match json.into_response() {
              Ok(resp) => {
                let resp = resp.map_err(SidecarError::from);
                self.peer.handle_response(request_id, resp);
              },
              Err(msg) => {
                error!("[RPC] failed to parse response: {}", msg);
                self
                  .peer
                  .handle_response(request_id, Err(SidecarError::InvalidResponse));
              },
            }
          } else {
            self.peer.put_rpc_object(Ok(json));
          }
        }
      });

      loop {
        let _guard = PanicGuard(&peer);
        let read_result = next_read(&peer, &ctx);
        let json = match read_result {
          Ok(json) => json,
          Err(err) => {
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

/// retrieves the next available read result from a peer, performing idle work if no result is
/// immediately available.
fn next_read<W>(peer: &RawPeer<W>, _ctx: &RpcCtx) -> Result<RpcObject, ReadError>
where
  W: Write + Send,
{
  loop {
    // Continuously checks if there is a result available from the peer using
    if let Some(result) = peer.try_get_rx() {
      return result;
    }

    let time_to_next_timer = match peer.check_timers() {
      Some(Ok(_token)) => continue,
      Some(Err(duration)) => Some(duration),
      None => None,
    };

    // Ensures the function does not block indefinitely by setting a maximum wait time
    let idle_timeout = time_to_next_timer
      .unwrap_or(MAX_IDLE_WAIT)
      .min(MAX_IDLE_WAIT);

    if let Some(result) = peer.get_rx_timeout(idle_timeout) {
      return result;
    }
  }
}
