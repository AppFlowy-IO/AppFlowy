#![allow(clippy::not_unsafe_ptr_arg_deref)]
mod c;
mod model;
mod protobuf;
mod util;

use crate::{
    c::{extend_front_four_bytes_into_bytes, forget_rust},
    model::{FFIRequest, FFIResponse},
};
use flowy_sdk::get_client_server_configuration;
use flowy_sdk::*;
use lib_dispatch::prelude::ToBytes;
use lib_dispatch::prelude::*;
use once_cell::sync::OnceCell;
use std::{ffi::CStr, os::raw::c_char};

static FLOWY_SDK: OnceCell<FlowySDK> = OnceCell::new();

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(path) };
    let path: &str = c_str.to_str().unwrap();

    let server_config = get_client_server_configuration().unwrap();
    let config = FlowySDKConfig::new(path, "appflowy", server_config, false).log_filter("debug");
    FLOWY_SDK.get_or_init(|| FlowySDK::new(config));

    0
}

#[no_mangle]
pub extern "C" fn async_event(port: i64, input: *const u8, len: usize) {
    let request: ModuleRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!(
        "[FFI]: {} Async Event: {:?} with {} port",
        &request.id,
        &request.event,
        port
    );

    let dispatcher = match FLOWY_SDK.get() {
        None => {
            log::error!("sdk not init yet.");
            return;
        }
        Some(e) => e.dispatcher.clone(),
    };
    let _ = EventDispatcher::async_send_with_callback(dispatcher, request, move |resp: EventResponse| {
        log::trace!("[FFI]: Post data to dart through {} port", port);
        Box::pin(post_to_flutter(resp, port))
    });
}

#[no_mangle]
pub extern "C" fn sync_event(input: *const u8, len: usize) -> *const u8 {
    let request: ModuleRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!("[FFI]: {} Sync Event: {:?}", &request.id, &request.event,);

    let dispatcher = match FLOWY_SDK.get() {
        None => {
            log::error!("sdk not init yet.");
            return forget_rust(Vec::default());
        }
        Some(e) => e.dispatcher.clone(),
    };
    let _response = EventDispatcher::sync_send(dispatcher, request);

    // FFIResponse {  }
    let response_bytes = vec![];
    let result = extend_front_four_bytes_into_bytes(&response_bytes);
    forget_rust(result)
}

#[no_mangle]
pub extern "C" fn set_stream_port(port: i64) -> i32 {
    dart_notify::dart::DartStreamSender::set_port(port);
    0
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

#[inline(always)]
async fn post_to_flutter(response: EventResponse, port: i64) {
    let isolate = allo_isolate::Isolate::new(port);
    match isolate
        .catch_unwind(async {
            let ffi_resp = FFIResponse::from(response);
            ffi_resp.into_bytes().unwrap().to_vec()
        })
        .await
    {
        Ok(_success) => {
            log::trace!("[FFI]: Post data to dart success");
        }
        Err(e) => {
            if let Some(msg) = e.downcast_ref::<&str>() {
                log::error!("[FFI]: {:?}", msg);
            } else {
                log::error!("[FFI]: allo_isolate post panic");
            }
        }
    }
}
