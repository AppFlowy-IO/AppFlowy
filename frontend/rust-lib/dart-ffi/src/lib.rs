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
use std::{ffi::CStr, os::raw::c_char};
use lazy_static::lazy_static;
use parking_lot::RwLock;

lazy_static! {
    static ref FLOWY_SDK: RwLock<Option<FlowySDK>> = RwLock::new(None);
}

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(path) };
    let path: &str = c_str.to_str().unwrap();

    let server_config = get_client_server_configuration().unwrap();
    let config = FlowySDKConfig::new(path, server_config).log_filter("info");
    *FLOWY_SDK.write() = Some(FlowySDK::new(config));

    0
}

#[no_mangle]
pub extern "C" fn async_event(port: i64, input: *const u8, len: usize) {
    let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!(
        "[FFI]: {} Async Event: {:?} with {} port",
        &request.id,
        &request.event,
        port
    );

    let dispatcher = match FLOWY_SDK.read().as_ref() {
        None => {
            log::error!("sdk not init yet.");
            return;
        }
        Some(e) => e.event_dispatcher.clone(),
    };
    let _ = AFPluginDispatcher::async_send_with_callback(dispatcher, request, move |resp: AFPluginEventResponse| {
        log::trace!("[FFI]: Post data to dart through {} port", port);
        Box::pin(post_to_flutter(resp, port))
    });
}

#[no_mangle]
pub extern "C" fn sync_event(input: *const u8, len: usize) -> *const u8 {
    let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
    log::trace!("[FFI]: {} Sync Event: {:?}", &request.id, &request.event,);

    let dispatcher = match FLOWY_SDK.read().as_ref() {
        None => {
            log::error!("sdk not init yet.");
            return forget_rust(Vec::default());
        }
        Some(e) => e.event_dispatcher.clone(),
    };
    let _response = AFPluginDispatcher::sync_send(dispatcher, request);

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
async fn post_to_flutter(response: AFPluginEventResponse, port: i64) {
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
