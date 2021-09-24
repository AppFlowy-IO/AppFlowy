use log::LevelFilter;

use tracing::subscriber::set_global_default;

use tracing_bunyan_formatter::{BunyanFormattingLayer, JsonStorageLayer};
use tracing_log::LogTracer;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter};

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

    pub fn build(self) -> std::result::Result<(), String> {
        let env_filter = EnvFilter::new(self.env_filter);
        let subscriber = tracing_subscriber::fmt()
            .with_target(true)
            .with_max_level(tracing::Level::TRACE)
            .with_writer(std::io::stderr)
            .with_thread_ids(false)
            .compact()
            .finish()
            .with(env_filter);

        let formatting_layer = BunyanFormattingLayer::new(self.name.clone(), std::io::stdout);
        let _ = set_global_default(subscriber.with(JsonStorageLayer).with(formatting_layer))
            .map_err(|e| format!("{:?}", e))?;

        let _ = LogTracer::builder()
            .with_max_level(LevelFilter::Debug)
            .init()
            .map_err(|e| format!("{:?}", e))
            .unwrap();

        Ok(())
    }
}
