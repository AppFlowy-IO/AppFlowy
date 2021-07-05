use log::LevelFilter;
use std::path::Path;
use tracing::subscriber::set_global_default;

use tracing_bunyan_formatter::{BunyanFormattingLayer, JsonStorageLayer};
use tracing_log::LogTracer;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter};

pub struct FlowyLogBuilder {
    name: String,
    env_filter: String,
    directory: String,
}

impl FlowyLogBuilder {
    pub fn new(name: &str, directory: impl AsRef<Path>) -> Self {
        let directory = directory.as_ref().to_str().unwrap().to_owned();

        FlowyLogBuilder {
            name: name.to_owned(),
            env_filter: "Info".to_owned(),
            directory,
        }
    }

    pub fn env_filter(mut self, env_filter: &str) -> Self {
        self.env_filter = env_filter.to_owned();
        self
    }

    pub fn build(self) -> std::result::Result<(), String> {
        let env_filter = EnvFilter::new(self.env_filter);

        let subscriber = tracing_subscriber::fmt()
            .with_target(false)
            .with_max_level(tracing::Level::TRACE)
            .with_writer(std::io::stderr)
            .with_thread_ids(false)
            .with_target(false)
            // .with_writer(non_blocking)
            .compact()
            .finish()
            .with(env_filter);

        if cfg!(feature = "use_bunyan") {
            let formatting_layer = BunyanFormattingLayer::new(self.name.clone(), std::io::stdout);

            let local_file_name = format!("{}.log", &self.name);
            let file_appender =
                tracing_appender::rolling::daily(self.directory.clone(), local_file_name);
            let (_non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

            let _ = set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer))
                .map_err(|e| format!("{:?}", e))?;
        } else {
            let _ = set_global_default(subscriber).map_err(|e| format!("{:?}", e))?;
        }
        let _ = LogTracer::builder()
            .with_max_level(LevelFilter::Trace)
            .init()
            .map_err(|e| format!("{:?}", e))
            .unwrap();

        Ok(())
    }
}

pub fn init_log(name: &str, directory: &str, env_filter: &str) -> std::result::Result<(), String> {
    FlowyLogBuilder::new(name, directory)
        .env_filter(env_filter)
        .build()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug)]
    struct Position {
        x: f32,
        y: f32,
    }

    #[test]
    fn test_log() {
        init_log("flowy", ".", "Debug").unwrap();
        tracing::info!("😁 Tracing info log");

        let pos = Position {
            x: 3.234,
            y: -1.223,
        };

        tracing::debug!(?pos.x, ?pos.y);
        log::debug!("😁 bridge 'log' to 'tracing'");
    }
}
