use crate::{response::EventResponse, rt::SystemCommand};
use futures_core::ready;
use std::{future::Future, task::Context};
use tokio::{
    macros::support::{Pin, Poll},
    sync::{mpsc::UnboundedReceiver, oneshot},
};

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {}

#[no_mangle]
pub extern "C" fn free_rust(ptr: *mut u8, length: u32) { reclaim_rust(ptr, length) }

#[no_mangle]
pub extern "C" fn init_stream(port: i64) -> i32 { return 0; }

struct SystemFFI {
    resp_rx: UnboundedReceiver<EventResponse>,
}

impl Future for SystemFFI {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.resp_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(resp) => {
                    log::trace!("Response: {:?}", resp);
                },
            }
        }
    }
}
