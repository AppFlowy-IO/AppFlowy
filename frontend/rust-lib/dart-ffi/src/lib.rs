#![allow(clippy::not_unsafe_ptr_arg_deref)]

use std::sync::Arc;
use std::{ffi::CStr, os::raw::c_char};

use lazy_static::lazy_static;
use parking_lot::Mutex;
use tracing::{debug, error, info, trace, warn};

use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::*;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use flowy_server_pub::AuthenticatorType;
use lib_dispatch::prelude::ToBytes;
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::AFPluginRuntime;

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
pub extern "C" fn init_sdk(_port: i64, data: *mut c_char) -> i64 {
  // and sent it the `Rust's` result
  // no need to convert anything :)
  let c_str = unsafe { CStr::from_ptr(data) };
  let serde_str = c_str.to_str().unwrap();
  let configuration = AppFlowyDartConfiguration::from_str(serde_str);
  configuration.write_env();

  if configuration.authenticator_type == AuthenticatorType::AppFlowyCloud {
    let _ = save_appflowy_cloud_config(&configuration.root, &configuration.appflowy_cloud_config);
  }

  let log_crates = vec!["flowy-ffi".to_string()];
  let config = AppFlowyCoreConfig::new(
    configuration.app_version,
    configuration.custom_app_path,
    configuration.origin_app_path,
    configuration.device_id,
    DEFAULT_NAME.to_string(),
  )
  .log_filter("info", log_crates);

  // Ensure that the database is closed before initialization. Also, verify that the init_sdk function can be called
  // multiple times (is reentrant). Currently, only the database resource is exclusive.
  if let Some(core) = &*APPFLOWY_CORE.0.lock() {
    core.close_db();
  }

  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  let cloned_runtime = runtime.clone();
  // let isolate = allo_isolate::Isolate::new(port);
  *APPFLOWY_CORE.0.lock() = runtime.block_on(async move {
    Some(AppFlowyCore::new(config, cloned_runtime).await)
    // isolate.post("".to_string());
  });
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
    dispatcher.as_ref(),
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
pub extern "C" fn rust_log(level: i64, data: *const c_char) {
  // Check if the data pointer is not null
  if data.is_null() {
    error!("[flutter error]: null pointer provided to backend_log");
    return;
  }

  let log_result = unsafe { CStr::from_ptr(data) }.to_str();

  // Handle potential UTF-8 conversion error
  let log_str = match log_result {
    Ok(str) => str,
    Err(e) => {
      error!(
        "[flutter error]: Failed to convert C string to Rust string: {:?}",
        e
      );
      return;
    },
  };

  // Simplify logging by determining the log level outside of the match
  let log_level = match level {
    0 => "info",
    1 => "debug",
    2 => "trace",
    3 => "warn",
    4 => "error",
    _ => {
      warn!("[flutter error]: Unsupported log level: {}", level);
      return;
    },
  };

  // Log the message at the appropriate level
  match log_level {
    "info" => info!("[Flutter]: {}", log_str),
    "debug" => debug!("[Flutter]: {}", log_str),
    "trace" => trace!("[Flutter]: {}", log_str),
    "warn" => warn!("[Flutter]: {}", log_str),
    "error" => error!("[Flutter]: {}", log_str),
    _ => {
      warn!("[flutter error]: Unsupported log level: {}", log_level);
    },
  }
}

#[no_mangle]
pub extern "C" fn set_env(_data: *const c_char) {
  // Deprecated
}
