mod layer;

use log::LevelFilter;
use std::path::Path;
use tracing::subscriber::set_global_default;

use crate::layer::*;
use tracing_bunyan_formatter::{BunyanFormattingLayer, JsonStorageLayer};
use tracing_log::LogTracer;
use tracing_subscriber::{fmt::format::FmtSpan, layer::SubscriberExt, EnvFilter};

pub struct Builder {
    name: String,
    env_filter: String,
}

impl Builder {
    pub fn new(name: &str) -> Self {
        Builder {
            name: name.to_owned(),
            env_filter: "Info".to_owned(),
        }
    }

    pub fn env_filter(mut self, env_filter: &str) -> Self {
        self.env_filter = env_filter.to_owned();
        self
    }

    pub fn local(self, directory: impl AsRef<Path>) -> Self {
        let directory = directory.as_ref().to_str().unwrap().to_owned();
        let local_file_name = format!("{}.log", &self.name);
        let file_appender = tracing_appender::rolling::daily(directory, local_file_name);
        let (_non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

        self
    }

    pub fn build(self) -> std::result::Result<(), String> {
        let env_filter = EnvFilter::new(self.env_filter);

        let subscriber = tracing_subscriber::fmt()
            // .with_span_events(FmtSpan::NEW | FmtSpan::CLOSE)
            .with_target(true)
            .with_max_level(tracing::Level::TRACE)
            .with_writer(std::io::stderr)
            .with_thread_ids(false)
            // .with_writer(non_blocking)
            // .json()
            .compact()
            .finish()
            .with(env_filter);

        // if cfg!(feature = "use_bunyan") {
        //     let formatting_layer = BunyanFormattingLayer::new(self.name.clone(),
        // std::io::stdout);     let _ =
        // set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer)).
        // map_err(|e| format!("{:?}", e))?; } else {
        //     let _ = set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
        // }

        let formatting_layer = FlowyFormattingLayer::new(std::io::stdout);
        let _ = set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer)).map_err(|e| format!("{:?}", e))?;

        let _ = LogTracer::builder()
            .with_max_level(LevelFilter::Trace)
            .init()
            .map_err(|e| format!("{:?}", e))
            .unwrap();

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
        let _ = Builder::new("flowy").env_filter("debug").build();
        tracing::info!("😁 Tracing info log");

        let pos = Position { x: 3.234, y: -1.223 };

        tracing::debug!(?pos.x, ?pos.y);
        log::debug!("😁 bridge 'log' to 'tracing'");

        say("hello world");
    }

    #[tracing::instrument(name = "say")]
    fn say(s: &str) {
        log::info!("{}", s);
    }
}
