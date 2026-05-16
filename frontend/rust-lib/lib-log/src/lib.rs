use std::io;
use std::io::Write;
use std::sync::{Arc, RwLock};

use crate::layer::FlowyFormattingLayer;
use crate::stream_log::{StreamLog, StreamLogSender};
use chrono::Local;
use lazy_static::lazy_static;
use lib_infra::util::OperatingSystem;
use tracing::subscriber::set_global_default;
use tracing_appender::rolling::Rotation;
use tracing_appender::{non_blocking::WorkerGuard, rolling::RollingFileAppender};
use tracing_bunyan_formatter::JsonStorageLayer;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::MakeWriter;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter};

mod layer;
pub mod stream_log;

lazy_static! {
  static ref APP_LOG_GUARD: RwLock<Option<WorkerGuard>> = RwLock::new(None);
  static ref COLLAB_SYNC_LOG_GUARD: RwLock<Option<WorkerGuard>> = RwLock::new(None);
}

pub struct Builder {
  #[allow(dead_code)]
  name: String,
  env_filter: String,
  app_log_appender: RollingFileAppender,
  sync_log_appender: RollingFileAppender,
  #[allow(dead_code)]
  platform: OperatingSystem,
  stream_log_sender: Option<Arc<dyn StreamLogSender>>,
}

const SYNC_TARGET: &str = "sync_trace_log";
impl Builder {
  pub fn new(
    name: &str,
    directory: &str,
    platform: &OperatingSystem,
    stream_log_sender: Option<Arc<dyn StreamLogSender>>,
  ) -> Self {
    let app_log_appender = RollingFileAppender::builder()
      .rotation(Rotation::DAILY)
      .filename_prefix(name)
      .max_log_files(6)
      .build(directory)
      .unwrap_or(tracing_appender::rolling::daily(directory, name));

    let sync_log_name = "log.sync";
    let sync_log_appender = RollingFileAppender::builder()
      .rotation(Rotation::HOURLY)
      .filename_prefix(sync_log_name)
      .max_log_files(24)
      .build(directory)
      .unwrap_or(tracing_appender::rolling::hourly(directory, sync_log_name));

    Builder {
      name: name.to_owned(),
      env_filter: "info".to_owned(),
      app_log_appender,
      sync_log_appender,
      platform: platform.clone(),
      stream_log_sender,
    }
  }

  pub fn env_filter(mut self, env_filter: &str) -> Self {
    env_filter.clone_into(&mut self.env_filter);
    self
  }

  pub fn build(self) -> Result<(), String> {
    let env_filter = EnvFilter::new(self.env_filter);
    let (appflowy_log_non_blocking, app_log_guard) =
      tracing_appender::non_blocking(self.app_log_appender);
    *APP_LOG_GUARD.write().unwrap() = Some(app_log_guard);
    let app_file_layer = FlowyFormattingLayer::new(appflowy_log_non_blocking)
      .with_target_filter(|target| target != SYNC_TARGET);

    let (sync_log_non_blocking, sync_log_guard) =
      tracing_appender::non_blocking(self.sync_log_appender);
    *COLLAB_SYNC_LOG_GUARD.write().unwrap() = Some(sync_log_guard);

    let collab_sync_file_layer = FlowyFormattingLayer::new(sync_log_non_blocking)
      .with_target_filter(|target| target == SYNC_TARGET);

    if let Some(stream_log_sender) = &self.stream_log_sender {
      let subscriber = tracing_subscriber::fmt()
        .with_timer(CustomTime)
        .with_max_level(tracing::Level::TRACE)
        .with_ansi(self.platform.is_desktop())
        .with_writer(StreamLog {
          sender: stream_log_sender.clone(),
        })
        .with_thread_ids(false)
        .pretty()
        .with_env_filter(env_filter)
        .finish()
        .with(JsonStorageLayer)
        .with(app_file_layer)
        .with(collab_sync_file_layer);
      set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
    } else {
      let subscriber = tracing_subscriber::fmt()
        .with_timer(CustomTime)
        .with_max_level(tracing::Level::TRACE)
        .with_ansi(true)
        .with_thread_ids(false)
        .pretty()
        .with_env_filter(env_filter)
        .finish()
        .with(FlowyFormattingLayer::new(DebugStdoutWriter))
        .with(JsonStorageLayer)
        .with(app_file_layer)
        .with(collab_sync_file_layer);
      set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
    };

    Ok(())
  }
}

struct CustomTime;
impl tracing_subscriber::fmt::time::FormatTime for CustomTime {
  fn format_time(&self, w: &mut Writer<'_>) -> std::fmt::Result {
    write!(w, "{}", Local::now().format("%Y-%m-%d %H:%M:%S"))
  }
}

pub struct DebugStdoutWriter;

impl<'a> MakeWriter<'a> for DebugStdoutWriter {
  type Writer = Box<dyn Write>;

  fn make_writer(&'a self) -> Self::Writer {
    if std::env::var("DISABLE_EVENT_LOG").unwrap_or("false".to_string()) == "true" {
      Box::new(io::sink())
    } else {
      Box::new(io::stdout())
    }
  }
}
