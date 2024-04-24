use std::io;
use std::io::Write;
use std::sync::{Arc, RwLock};

use chrono::Local;
use lazy_static::lazy_static;
use lib_infra::util::Platform;
use tracing::subscriber::set_global_default;
use tracing_appender::rolling::Rotation;
use tracing_appender::{non_blocking::WorkerGuard, rolling::RollingFileAppender};
use tracing_bunyan_formatter::JsonStorageLayer;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::MakeWriter;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter};

use crate::layer::FlowyFormattingLayer;
use crate::stream_log::{StreamLog, StreamLogSender};

mod layer;
pub mod stream_log;

lazy_static! {
  static ref LOG_GUARD: RwLock<Option<WorkerGuard>> = RwLock::new(None);
}

pub struct Builder {
  #[allow(dead_code)]
  name: String,
  env_filter: String,
  file_appender: RollingFileAppender,
  #[allow(dead_code)]
  platform: Platform,
  stream_log_sender: Option<Arc<dyn StreamLogSender>>,
}

impl Builder {
  pub fn new(
    name: &str,
    directory: &str,
    platform: &Platform,
    stream_log_sender: Option<Arc<dyn StreamLogSender>>,
  ) -> Self {
    let file_appender = RollingFileAppender::builder()
      .rotation(Rotation::DAILY)
      .filename_prefix(name)
      .max_log_files(6)
      .build(directory)
      .unwrap_or(tracing_appender::rolling::daily(directory, name));

    Builder {
      name: name.to_owned(),
      env_filter: "info".to_owned(),
      file_appender,
      platform: platform.clone(),
      stream_log_sender,
    }
  }

  pub fn env_filter(mut self, env_filter: &str) -> Self {
    self.env_filter = env_filter.to_owned();
    self
  }

  pub fn build(self) -> Result<(), String> {
    let env_filter = EnvFilter::new(self.env_filter);
    let (non_blocking, guard) = tracing_appender::non_blocking(self.file_appender);
    let file_layer = FlowyFormattingLayer::new(non_blocking);

    if let Some(stream_log_sender) = &self.stream_log_sender {
      let subscriber = tracing_subscriber::fmt()
        .with_timer(CustomTime)
        .with_max_level(tracing::Level::TRACE)
        .with_ansi(self.platform.is_not_ios())
        .with_writer(StreamLog {
          sender: stream_log_sender.clone(),
        })
        .with_thread_ids(false)
        .pretty()
        .with_env_filter(env_filter)
        .finish()
        .with(JsonStorageLayer)
        .with(file_layer);
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
        .with(JsonStorageLayer)
        .with(FlowyFormattingLayer::new(DebugStdoutWriter))
        .with(file_layer);
      set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
    };

    *LOG_GUARD.write().unwrap() = Some(guard);
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
