#![allow(clippy::not_unsafe_ptr_arg_deref)]

use allo_isolate::Isolate;
use lazy_static::lazy_static;
use semver::Version;
use std::rc::Rc;
use std::sync::{mpsc, Arc, RwLock};
use std::{ffi::CStr, os::raw::c_char};
use tokio::task::LocalSet;
use tracing::{debug, error, info, trace, warn};

use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::*;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use flowy_server_pub::AuthenticatorType;
use lib_dispatch::prelude::ToBytes;
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::AFPluginRuntime;
use lib_log::stream_log::StreamLogSender;

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

lazy_static! {
  static ref DART_APPFLOWY_CORE: DartAppFlowyCore = DartAppFlowyCore::new();
  static ref LOG_STREAM_ISOLATE: RwLock<Option<Isolate>> = RwLock::new(None);
}

pub struct Task {
  dispatcher: Arc<AFPluginDispatcher>,
  request: AFPluginRequest,
  port: i64,
  ret: Option<mpsc::Sender<DispatchFuture<AFPluginEventResponse>>>,
}

unsafe impl Send for Task {}
unsafe impl Sync for DartAppFlowyCore {}

struct DartAppFlowyCore {
  core: Arc<RwLock<Option<AppFlowyCore>>>,
  handle: RwLock<Option<std::thread::JoinHandle<()>>>,
  sender: RwLock<Option<mpsc::Sender<Task>>>,
}

impl DartAppFlowyCore {
  fn new() -> Self {
    Self {
      core: Arc::new(RwLock::new(None)),
      handle: RwLock::new(None),
      sender: RwLock::new(None),
    }
  }

  fn dispatcher(&self) -> Option<Arc<AFPluginDispatcher>> {
    let binding = self
      .core
      .read()
      .expect("Failed to acquire read lock for core");
    let core = binding.as_ref();
    core.map(|core| core.event_dispatcher.clone())
  }

  fn dispatch(
    &self,
    request: AFPluginRequest,
    port: i64,
    ret: Option<mpsc::Sender<DispatchFuture<AFPluginEventResponse>>>,
  ) {
    if let Ok(sender_guard) = self.sender.read() {
      if let Err(e) = sender_guard.as_ref().unwrap().send(Task {
        dispatcher: self.dispatcher().unwrap(),
        request,
        port,
        ret,
      }) {
        error!("Failed to send task: {}", e);
      }
    } else {
      warn!("Failed to acquire read lock for sender");
      return;
    }
  }
}

#[no_mangle]
pub extern "C" fn init_sdk(_port: i64, data: *mut c_char) -> i64 {
  let c_str = unsafe {
    if data.is_null() {
      return -1;
    }
    CStr::from_ptr(data)
  };
  let serde_str = c_str
    .to_str()
    .expect("Failed to convert C string to Rust string");
  let configuration = AppFlowyDartConfiguration::from_str(serde_str);
  configuration.write_env();

  if configuration.authenticator_type == AuthenticatorType::AppFlowyCloud {
    let _ = save_appflowy_cloud_config(&configuration.root, &configuration.appflowy_cloud_config);
  }

  let mut app_version =
    Version::parse(&configuration.app_version).unwrap_or_else(|_| Version::new(0, 5, 8));

  let min_version = Version::new(0, 5, 8);
  if app_version < min_version {
    app_version = min_version;
  }

  let config = AppFlowyCoreConfig::new(
    app_version,
    configuration.custom_app_path,
    configuration.origin_app_path,
    configuration.device_id,
    configuration.platform,
    DEFAULT_NAME.to_string(),
  );

  if let Some(core) = &*DART_APPFLOWY_CORE.core.write().unwrap() {
    core.close_db();
  }

  let log_stream = LOG_STREAM_ISOLATE
    .write()
    .unwrap()
    .take()
    .map(|isolate| Arc::new(LogStreamSenderImpl { isolate }) as Arc<dyn StreamLogSender>);
  let (sender, task_rx) = mpsc::channel::<Task>();
  let handle = std::thread::spawn(move || {
    let local_set = LocalSet::new();
    while let Ok(task) = task_rx.recv() {
      let Task {
        dispatcher,
        request,
        port,
        ret,
      } = task;
      let resp = AFPluginDispatcher::boxed_async_send_with_callback(
        dispatcher.as_ref(),
        request,
        move |resp: AFPluginEventResponse| {
          #[cfg(feature = "sync_verbose_log")]
          trace!("[FFI]: Post data to dart through {} port", port);
          Box::pin(post_to_flutter(resp, port))
        },
        &local_set,
      );

      if let Some(mut ret) = ret {
        let _ = ret.send(resp);
      }
    }
  });

  *DART_APPFLOWY_CORE.sender.write().unwrap() = Some(sender);
  *DART_APPFLOWY_CORE.handle.write().unwrap() = Some(handle);
  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  let cloned_runtime = runtime.clone();
  *DART_APPFLOWY_CORE.core.write().unwrap() = runtime
    .block_on(async move { Some(AppFlowyCore::new(config, cloned_runtime, log_stream).await) });
  0
}

#[no_mangle]
#[allow(clippy::let_underscore_future)]
pub extern "C" fn async_event(port: i64, input: *const u8, len: usize) {
  let request: AFPluginRequest = FFIRequest::from_u8_pointer(input, len).into();
  #[cfg(feature = "sync_verbose_log")]
  trace!(
    "[FFI]: {} Async Event: {:?} with {} port",
    &request.id,
    &request.event,
    port
  );

  DART_APPFLOWY_CORE.dispatch(request, port, None);
}

#[no_mangle]
pub extern "C" fn sync_event(_input: *const u8, _len: usize) -> *const u8 {
  error!("unimplemented sync_event");

  let response_bytes = vec![];
  let result = extend_front_four_bytes_into_bytes(&response_bytes);
  forget_rust(result)
}

#[no_mangle]
pub extern "C" fn set_stream_port(notification_port: i64) -> i32 {
  unregister_all_notification_sender();
  register_notification_sender(DartNotificationSender::new(notification_port));
  0
}

#[no_mangle]
pub extern "C" fn set_log_stream_port(port: i64) -> i32 {
  *LOG_STREAM_ISOLATE.write().unwrap() = Some(Isolate::new(port));
  0
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

#[inline(always)]
async fn post_to_flutter(response: AFPluginEventResponse, port: i64) {
  let isolate = allo_isolate::Isolate::new(port);
  if let Ok(_) = isolate
    .catch_unwind(async {
      let ffi_resp = FFIResponse::from(response);
      ffi_resp.into_bytes().unwrap().to_vec()
    })
    .await
  {
    #[cfg(feature = "sync_verbose_log")]
    trace!("[FFI]: Post data to dart success");
  } else {
    error!("[FFI]: allo_isolate post panic");
  }
}

#[no_mangle]
pub extern "C" fn rust_log(level: i64, data: *const c_char) {
  if data.is_null() {
    error!("[flutter error]: null pointer provided to backend_log");
    return;
  }

  let log_result = unsafe { CStr::from_ptr(data) }.to_str();

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

  match level {
    0 => info!("[Flutter]: {}", log_str),
    1 => debug!("[Flutter]: {}", log_str),
    2 => trace!("[Flutter]: {}", log_str),
    3 => warn!("[Flutter]: {}", log_str),
    4 => error!("[Flutter]: {}", log_str),
    _ => warn!("[flutter error]: Unsupported log level: {}", level),
  }
}

#[no_mangle]
pub extern "C" fn set_env(_data: *const c_char) {
  // Deprecated
}

struct LogStreamSenderImpl {
  isolate: Isolate,
}
impl StreamLogSender for LogStreamSenderImpl {
  fn send(&self, message: &[u8]) {
    self.isolate.post(message.to_vec());
  }
}
