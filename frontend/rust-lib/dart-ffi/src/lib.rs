#![allow(clippy::not_unsafe_ptr_arg_deref)]

use std::{ffi::CStr, os::raw::c_char};

use lazy_static::lazy_static;
use parking_lot::RwLock;

use flowy_core::*;
use flowy_notification::register_notification_sender;
use lib_dispatch::prelude::ToBytes;
use lib_dispatch::prelude::*;

use crate::env_serde::AppFlowyEnv;
use crate::notification::DartNotificationSender;
use crate::{
  c::{extend_front_four_bytes_into_bytes, forget_rust},
  model::{FFIRequest, FFIResponse},
};

mod c;
mod env_serde;
mod model;
mod notification;
mod protobuf;
mod util;

lazy_static! {
  static ref APPFLOWY_CORE: RwLock<Option<AppFlowyCore>> = RwLock::new(None);
}

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
  let c_str: &CStr = unsafe { CStr::from_ptr(path) };
  let path: &str = c_str.to_str().unwrap();

  let log_crates = vec!["flowy-ffi".to_string()];
  let config =
    AppFlowyCoreConfig::new(path, DEFAULT_NAME.to_string()).log_filter("info", log_crates);
  *APPFLOWY_CORE.write() = Some(AppFlowyCore::new(config));

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

  let dispatcher = match APPFLOWY_CORE.read().as_ref() {
    None => {
      log::error!("sdk not init yet.");
      return;
    },
    Some(e) => e.event_dispatcher.clone(),
  };
  let _ = AFPluginDispatcher::async_send_with_callback(
    dispatcher,
    request,
    move |resp: AFPluginEventResponse| {
      log::trace!("[FFI]: Post data to dart through {} port", port);
      Box::pin(post_to_flutter(resp, port))
    },
  );
}

#[no_mangle]
pub extern "C" fn sync_event(input: *const u8, len: usize) -> *const u8 {
  let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
  log::trace!("[FFI]: {} Sync Event: {:?}", &request.id, &request.event,);

  let dispatcher = match APPFLOWY_CORE.read().as_ref() {
    None => {
      log::error!("sdk not init yet.");
      return forget_rust(Vec::default());
    },
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
  register_notification_sender(DartNotificationSender::new(port));
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

#[no_mangle]
pub extern "C" fn backend_log(level: i64, data: *const c_char) {
  let c_str = unsafe { CStr::from_ptr(data) };
  let log_str = c_str.to_str().unwrap();

  // Don't change the mapping relation between number and level
  match level {
    0 => tracing::info!("{}", log_str),
    1 => tracing::debug!("{}", log_str),
    2 => tracing::trace!("{}", log_str),
    3 => tracing::warn!("{}", log_str),
    4 => tracing::error!("{}", log_str),
    _ => (),
  }
}

#[no_mangle]
pub extern "C" fn set_env(data: *const c_char) {
  let c_str = unsafe { CStr::from_ptr(data) };
  let serde_str = c_str.to_str().unwrap();
  AppFlowyEnv::parser(serde_str);
}
