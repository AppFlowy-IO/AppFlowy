#![allow(clippy::not_unsafe_ptr_arg_deref)]

use std::sync::Arc;
use std::{ffi::CStr, os::raw::c_char};

use lazy_static::lazy_static;
use parking_lot::Mutex;
use tracing::{error, trace};

use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::*;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use flowy_server_config::AuthenticatorType;
use lib_dispatch::prelude::ToBytes;
use lib_dispatch::prelude::*;

use crate::appflowy_yaml::save_appflowy_cloud_config;
use crate::env_serde::AppFlowyDartConfiguration;
use crate::notification::DartNotificationSender;
use crate::{
  c::{extend_front_four_bytes_into_bytes, forget_rust},
  model::{FFIRequest, FFIResponse},
};

mod appflowy_yaml;
mod c;
mod env_serde;
mod model;
mod notification;
mod protobuf;
mod util;

lazy_static! {
  static ref APPFLOWY_CORE: MutexAppFlowyCore = MutexAppFlowyCore::new();
}

struct MutexAppFlowyCore(Arc<Mutex<Option<AppFlowyCore>>>);

impl MutexAppFlowyCore {
  fn new() -> Self {
    Self(Arc::new(Mutex::new(None)))
  }

  fn dispatcher(&self) -> Option<Arc<AFPluginDispatcher>> {
    let binding = self.0.lock();
    let core = binding.as_ref();
    core.map(|core| core.event_dispatcher.clone())
  }
}

unsafe impl Sync for MutexAppFlowyCore {}
unsafe impl Send for MutexAppFlowyCore {}

#[no_mangle]
pub extern "C" fn init_sdk(data: *mut c_char) -> i64 {
  let c_str = unsafe { CStr::from_ptr(data) };
  let serde_str = c_str.to_str().unwrap();
  let configuration = AppFlowyDartConfiguration::from_str(serde_str);
  configuration.write_env();

  if configuration.authenticator_type == AuthenticatorType::AppFlowyCloud {
    let _ = save_appflowy_cloud_config(&configuration.root, &configuration.appflowy_cloud_config);
  }

  let log_crates = vec!["flowy-ffi".to_string()];
  let config = AppFlowyCoreConfig::new(
    configuration.custom_app_path,
    configuration.origin_app_path,
    configuration.device_id,
    DEFAULT_NAME.to_string(),
  )
  .log_filter("info", log_crates);
  *APPFLOWY_CORE.0.lock() = Some(AppFlowyCore::new(config));
  0
}

#[no_mangle]
#[allow(clippy::let_underscore_future)]
pub extern "C" fn async_event(port: i64, input: *const u8, len: usize) {
  let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
  trace!(
    "[FFI]: {} Async Event: {:?} with {} port",
    &request.id,
    &request.event,
    port
  );

  let dispatcher = match APPFLOWY_CORE.dispatcher() {
    None => {
      error!("sdk not init yet.");
      return;
    },
    Some(dispatcher) => dispatcher,
  };
  AFPluginDispatcher::boxed_async_send_with_callback(
    dispatcher,
    request,
    move |resp: AFPluginEventResponse| {
      trace!("[FFI]: Post data to dart through {} port", port);
      Box::pin(post_to_flutter(resp, port))
    },
  );
}

#[no_mangle]
pub extern "C" fn sync_event(input: *const u8, len: usize) -> *const u8 {
  let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
  trace!("[FFI]: {} Sync Event: {:?}", &request.id, &request.event,);

  let dispatcher = match APPFLOWY_CORE.dispatcher() {
    None => {
      error!("sdk not init yet.");
      return forget_rust(Vec::default());
    },
    Some(dispatcher) => dispatcher,
  };
  let _response = AFPluginDispatcher::sync_send(dispatcher, request);

  // FFIResponse {  }
  let response_bytes = vec![];
  let result = extend_front_four_bytes_into_bytes(&response_bytes);
  forget_rust(result)
}

#[no_mangle]
pub extern "C" fn set_stream_port(port: i64) -> i32 {
  // Make sure hot reload won't register the notification sender twice
  unregister_all_notification_sender();
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
      trace!("[FFI]: Post data to dart success");
    },
    Err(e) => {
      if let Some(msg) = e.downcast_ref::<&str>() {
        error!("[FFI]: {:?}", msg);
      } else {
        error!("[FFI]: allo_isolate post panic");
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
pub extern "C" fn set_env(_data: *const c_char) {
  // Deprecated
}
