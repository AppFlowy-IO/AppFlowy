mod c;
mod model;
mod protobuf;
mod util;

use crate::{
    c::{extend_front_four_bytes_into_bytes, forget_rust},
    model::{FFIRequest, FFIResponse},
};
use flowy_dispatch::prelude::*;
use flowy_sdk::*;
use lazy_static::lazy_static;
use std::{ffi::CStr, os::raw::c_char};

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

    log::info!("🔥 FlowySDK start running");
    FlowySDK::init(path);
    return 1;
}

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let request: ModuleRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!(
        "[FFI]: {} Async Event: {:?} with {} port",
        &request.id(),
        &request.event(),
        port
    );

    let _ = EventDispatch::async_send(request, move |resp: EventResponse| {
        log::trace!("[FFI]: Post data to dart through {} port", port);
        Box::pin(post_to_flutter(resp, port))
    });
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 {
    let request: ModuleRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!(
        "[FFI]: {} Sync Event: {:?}",
        &request.id(),
        &request.event(),
    );
    let _response = EventDispatch::sync_send(request);

    // FFIResponse {  }
    let response_bytes = vec![];
    let result = extend_front_four_bytes_into_bytes(&response_bytes);
    forget_rust(result)
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

use flowy_dispatch::prelude::ToBytes;
#[inline(always)]
async fn post_to_flutter(response: EventResponse, port: i64) {
    let isolate = allo_isolate::Isolate::new(port);
    match isolate
        .catch_unwind(async {
            let ffi_resp = FFIResponse::from(response);
            ffi_resp.into_bytes().unwrap()
        })
        .await
    {
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
