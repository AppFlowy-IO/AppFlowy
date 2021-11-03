mod layer;

use log::LevelFilter;
use std::path::Path;
use tracing::subscriber::set_global_default;

use crate::layer::*;
use lazy_static::lazy_static;
use std::sync::RwLock;
use tracing_appender::{non_blocking::WorkerGuard, rolling::RollingFileAppender};
use tracing_bunyan_formatter::JsonStorageLayer;
use tracing_log::LogTracer;
use tracing_subscriber::{field::MakeExt, fmt::format, layer::SubscriberExt, EnvFilter};

lazy_static! {
    static ref LOG_GUARD: RwLock<Option<WorkerGuard>> = RwLock::new(None);
}

pub struct Builder {
    name: String,
    env_filter: String,
    file_appender: Option<RollingFileAppender>,
}

impl Builder {
    pub fn new(name: &str) -> Self {
        Builder {
            name: name.to_owned(),
            env_filter: "Info".to_owned(),
            file_appender: None,
        }
    }

    pub fn env_filter(mut self, env_filter: &str) -> Self {
        self.env_filter = env_filter.to_owned();
        self
    }

    pub fn local(mut self, directory: impl AsRef<Path>) -> Self {
        let directory = directory.as_ref().to_str().unwrap().to_owned();
        let local_file_name = format!("{}.log", &self.name);
        self.file_appender = Some(tracing_appender::rolling::daily(directory, local_file_name));

        self
    }

    pub fn build(self) -> std::result::Result<(), String> {
        let env_filter = EnvFilter::new(self.env_filter);
        let file_appender = self.file_appender.unwrap();
        let (non_blocking, guard) = tracing_appender::non_blocking(file_appender);
        let subscriber = tracing_subscriber::fmt()
            // .with_span_events(FmtSpan::NEW | FmtSpan::CLOSE)
            .with_ansi(false)
            .with_target(false)
            .with_max_level(tracing::Level::TRACE)
            .with_writer(std::io::stderr)
            .with_thread_ids(true)
            // .with_writer(non_blocking)
            .json()
            .with_current_span(true)
            .with_span_list(true)
            .compact()
            .finish()
            .with(env_filter).with(JsonStorageLayer)
            .with(FlowyFormattingLayer::new(std::io::stdout))
            .with(FlowyFormattingLayer::new(non_blocking));

        // if cfg!(feature = "use_bunyan") {
        //     let formatting_layer = BunyanFormattingLayer::new(self.name.clone(),
        // std::io::stdout);     let _ =
        // set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer)).
        // map_err(|e| format!("{:?}", e))?; } else {
        //     let _ = set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
        // }

        let _ = set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
        let _ = LogTracer::builder()
            .with_max_level(LevelFilter::Trace)
            .init()
            .map_err(|e| format!("{:?}", e))
            .unwrap();

        *LOG_GUARD.write().unwrap() = Some(guard);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug)]
    struct Position {
        x: f32,
        y: f32,
    }

    // run  cargo test --features="use_bunyan" or  cargo test
    #[test]
    fn test_log() {
        let _ = Builder::new("flowy").local(".").env_filter("debug").build().unwrap();
        tracing::info!("😁  tracing::info call");
        log::debug!("😁 log::debug call");

        say("hello world");
    }

    #[test]
    fn test_log2() {
        let env_filter = EnvFilter::new("Debug");
        let file_appender = tracing_appender::rolling::daily(".", "flowy_log_test");
        let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

        let subscriber = tracing_subscriber::fmt()
            .with_target(false)
            .with_max_level(tracing::Level::TRACE)
            .with_writer(std::io::stderr)
            .with_thread_ids(true)
            .with_writer(non_blocking)
            .json()
            .compact()
            .finish()
            .with(env_filter);

        let formatting_layer = FlowyFormattingLayer::new(std::io::stdout);
        let _ = set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer))
            .map_err(|e| format!("{:?}", e))
            .unwrap();

        let _ = LogTracer::builder()
            .with_max_level(LevelFilter::Trace)
            .init()
            .map_err(|e| format!("{:?}", e))
            .unwrap();

        tracing::info!("😁");
    }

    #[tracing::instrument(name = "say")]
    fn say(s: &str) {
        tracing::info!("{}", s);
    }
}
