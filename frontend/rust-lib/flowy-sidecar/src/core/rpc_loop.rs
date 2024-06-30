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
use tracing::{error, trace};

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
  /// Implements the cleanup behavior when the guard is dropped.
  ///
  /// This method is automatically called when the `PanicGuard` goes out of scope.
  /// It checks if a panic is occurring and, if so, logs an error message and
  /// disconnects the peer.
  fn drop(&mut self) {
    // - If no panic is occurring, this method does nothing.
    // - If a panic is detected:
    //   1. An error message is logged.
    //   2. The `disconnect()` method is called on the peer.
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

  /// Starts and manages the main event loop for processing RPC messages.
  ///
  /// This function is the core of the RPC system, handling incoming messages,
  /// dispatching requests to the appropriate handler, and managing the overall
  /// lifecycle of the RPC communication.
  ///
  /// # Arguments
  ///
  /// * `&mut self` - A mutable reference to the `RpcLoop` instance.
  /// * `_plugin_name: &str` - The name of the plugin (currently unused in the function body).
  /// * `buffer_read_fn: BufferReadFn` - A closure that returns a `BufRead` instance for reading input.
  /// * `handler: &mut H` - A mutable reference to the handler implementing the `Handler` trait.
  ///
  /// # Type Parameters
  ///
  /// * `R: BufRead` - The type returned by `buffer_read_fn`, must implement `BufRead`.
  /// * `BufferReadFn: Send + FnOnce() -> R` - The type of the closure that provides the input reader.
  /// * `H: Handler` - The type of the handler, must implement the `Handler` trait.
  ///
  /// # Returns
  ///
  /// * `Result<(), ReadError>` - Returns `Ok(())` if the loop exits normally (EOF),
  ///   or an error if an unrecoverable error occurs.
  ///
  /// # Behavior
  ///
  /// 1. Creates a new `RpcCtx` with a clone of the `RawPeer`.
  /// 2. Spawns a separate thread for reading input using `crossbeam_utils::thread::scope`.
  /// 3. In the reading thread:
  ///    - Continuously reads and parses JSON messages from the input.
  ///    - Handles responses by calling `handle_response` on the peer.
  ///    - Puts other messages into the peer's queue using `put_rpc_object`.
  /// 4. In the main thread:
  ///    - Retrieves messages using `next_read`.
  ///    - Processes requests by calling the handler's `handle_request` method.
  ///    - Sends responses back using the peer's `respond` method.
  /// 5. Continues looping until an error occurs or the peer is disconnected.
  pub fn mainloop<R, BufferReadFn, H>(
    &mut self,
    _plugin_name: &str,
    buffer_read_fn: BufferReadFn,
    handler: &mut H,
  ) -> Result<(), ReadError>
  where
    R: BufRead,
    BufferReadFn: Send + FnOnce() -> R,
    H: Handler,
  {
    // uses `crossbeam_utils::thread::scope` for thread management,
    // which offers several advantages over `std::thread`:
    // 1. Scoped Threads: Guarantees thread termination when the scope ends,
    //    preventing resource leaks.
    // 2. Simplified Lifetime Management: Allows threads to borrow data from
    //    their parent stack frame, enabling more ergonomic code.
    // 3. Improved Safety: Prevents threads from outliving the data they operate on,
    //    reducing risks of data races and use-after-free errors.
    // 4. Efficiency: Potentially more efficient due to known thread lifetimes,
    //    leading to better resource management.
    // 5. Error Propagation: Simplifies propagating errors from spawned threads
    //    back to the parent thread.
    // 6. Consistency with Rust's Ownership Model: Aligns well with Rust's
    //    ownership and borrowing rules.
    // 7. Automatic Thread Joining: No need for manual thread joining, reducing
    //    the risk of thread management errors.
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

      // Main processing loop
      loop {
        // `PanicGuard` is a critical safety mechanism in the RPC system. It's designed to detect
        // panics that occur during RPC request handling and ensure that the system shuts down
        // gracefully, preventing resource leaks and maintaining system integrity.
        //
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
          Ok(Call::Message(_msg)) => {
            #[cfg(feature = "verbose")]
            trace!("[RPC {}]: {}", _plugin_name, _msg);
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
