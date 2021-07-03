mod c;

use crate::c::forget_rust;
use flowy_sdk::*;
use flowy_sys::prelude::*;
use lazy_static::lazy_static;
use std::{cell::RefCell, ffi::CStr, future::Future, os::raw::c_char};

lazy_static! {
    pub static ref FFI_RUNTIME: tokio::runtime::Runtime =
        tokio::runtime::Builder::new_current_thread()
            .thread_name("flowy-dart-ffi")
            .build()
            .unwrap();
}

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(path) };
    let path: &str = c_str.to_str().unwrap();
    FlowySDK::init_log(path);
    FlowySDK::init(path);
    return 1;
}

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let FFICommand { event, payload } = FFICommand::from_u8_pointer(input, len);
    let mut request = DispatchRequest::new(event);
    log::trace!(
        "[FFI]: {} Async Event: {:?} with {} port",
        &request.id,
        &request.event,
        port
    );
    if !payload.is_empty() {
        request = request.payload(Payload::Bytes(payload));
    }

    request = request.callback(Box::new(move |resp: EventResponse| {
        let bytes = match resp.data {
            ResponseData::Bytes(bytes) => bytes,
            ResponseData::None => vec![],
        };
        log::trace!("[FFI]: Post data to dart through {} port", port);
        Box::pin(spawn_future(async { bytes }, port))
    }));

    let _ = EventDispatch::async_send(request);
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 { unimplemented!() }

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

#[derive(serde::Deserialize)]
pub struct FFICommand {
    event: String,
    payload: Vec<u8>,
}

impl FFICommand {
    pub fn from_u8_pointer(pointer: *const u8, len: usize) -> Self {
        let bytes = unsafe { std::slice::from_raw_parts(pointer, len) }.to_vec();
        let command: FFICommand = serde_json::from_slice(&bytes).unwrap();
        command
    }
}

#[inline(always)]
async fn spawn_future<F>(future: F, port: i64)
where
    F: Future<Output = Vec<u8>> + Send + 'static,
{
    let isolate = allo_isolate::Isolate::new(port);
    match isolate.catch_unwind(future).await {
        Ok(success) => {
            log::trace!("[FFI]: Post data to dart success");
        },
        Err(e) => {
            if let Some(msg) = e.downcast_ref::<&str>() {
                log::error!("[FFI]: ❌ {:?}", msg);
            } else {
                log::error!("[FFI]: allo_isolate post panic");
            }
        },
    }
}
