mod chat_test;
mod complete_test;
mod summary_test;
mod translate_test;

use std::sync::Once;
use tracing_subscriber::fmt::Subscriber;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    let level = std::env::var("RUST_LOG").unwrap_or("trace".to_string());
    let mut filters = vec![];
    filters.push(format!("flowy_ai={}", level));
    std::env::set_var("RUST_LOG", filters.join(","));

    let subscriber = Subscriber::builder()
      .with_ansi(true)
      .with_env_filter(EnvFilter::from_default_env())
      .finish();
    subscriber.try_init().unwrap();
  });
}
