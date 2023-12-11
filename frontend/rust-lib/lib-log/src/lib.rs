use std::sync::RwLock;

use chrono::Local;
use lazy_static::lazy_static;
use tracing::subscriber::set_global_default;
use tracing_appender::{non_blocking::WorkerGuard, rolling::RollingFileAppender};
use tracing_bunyan_formatter::JsonStorageLayer;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter};

use crate::layer::FlowyFormattingLayer;

mod layer;

lazy_static! {
  static ref LOG_GUARD: RwLock<Option<WorkerGuard>> = RwLock::new(None);
}

pub struct Builder {
  #[allow(dead_code)]
  name: String,
  env_filter: String,
  file_appender: RollingFileAppender,
}

impl Builder {
  pub fn new(name: &str, directory: &str) -> Self {
    Builder {
      name: name.to_owned(),
      env_filter: "Info".to_owned(),
      file_appender: tracing_appender::rolling::daily(directory, name),
    }
  }

  pub fn env_filter(mut self, env_filter: &str) -> Self {
    self.env_filter = env_filter.to_owned();
    self
  }

  pub fn build(self) -> std::result::Result<(), String> {
    let env_filter = EnvFilter::new(self.env_filter);

    let (non_blocking, guard) = tracing_appender::non_blocking(self.file_appender);
    let subscriber = tracing_subscriber::fmt()
      .with_timer(CustomTime)
      .with_ansi(true)
      .with_target(false)
      .with_max_level(tracing::Level::TRACE)
      .with_thread_ids(false)
      .with_writer(std::io::stderr)
      .pretty()
      .with_env_filter(env_filter)
      .finish()
      .with(JsonStorageLayer)
      .with(FlowyFormattingLayer::new(non_blocking));

    set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;

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
