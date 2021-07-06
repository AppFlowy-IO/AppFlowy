mod c;
mod model;
mod protobuf;

use crate::{
    c::{extend_front_four_bytes_into_bytes, forget_rust},
    protobuf::FFIRequest,
};
use flowy_sdk::*;
use flowy_sys::prelude::*;
use lazy_static::lazy_static;
use std::{ffi::CStr, future::Future, os::raw::c_char};

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
    let mut request: DispatchRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!(
        "[FFI]: {} Async Event: {:?} with {} port",
        &request.id,
        &request.event,
        port
    );

    request = request.callback(Box::new(move |resp: EventResponse| {
        let bytes = match resp.payload {
            Payload::Bytes(bytes) => bytes,
            Payload::None => vec![],
        };
        log::trace!("[FFI]: Post data to dart through {} port", port);
        Box::pin(spawn_future(async { bytes }, port))
    }));

    let _ = EventDispatch::async_send(request);
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 {
    let request: DispatchRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!("[FFI]: {} Sync Event: {:?}", &request.id, &request.event,);
    let _response = EventDispatch::sync_send(request);

    // FFIResponse {  }
    let response_bytes = vec![];
    let result = extend_front_four_bytes_into_bytes(&response_bytes);
    forget_rust(result)
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

#[inline(always)]
async fn spawn_future<F>(future: F, port: i64)
where
    F: Future<Output = Vec<u8>> + Send + 'static,
{
    let isolate = allo_isolate::Isolate::new(port);
    match isolate.catch_unwind(future).await {
        Ok(_success) => {
            log::trace!("[FFI]: Post data to dart success");
        },
        Err(e) => {
            if let Some(msg) = e.downcast_ref::<&str>() {
                log::error!("[FFI]: {:?}", msg);
            } else {
                log::error!("[FFI]: allo_isolate post panic");
            }
        },
    }
}

impl std::convert::From<FFIRequest> for DispatchRequest {
    fn from(ffi_request: FFIRequest) -> Self {
        let payload = if !ffi_request.payload.is_empty() {
            Payload::Bytes(ffi_request.payload)
        } else {
            Payload::None
        };
        let request = DispatchRequest::new(ffi_request.event).payload(payload);
        request
    }
}
