use appflowy_integrate::collab_builder::{AppFlowyCollabBuilder, CloudStorageType};

use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
use parking_lot::Once;
use tempfile::TempDir;
use tracing_subscriber::{fmt::Subscriber, util::SubscriberInitExt, EnvFilter};

use flowy_document2::manager::DocumentUser;

pub struct FakeUser {
  kv: Arc<RocksCollabDB>,
}

impl FakeUser {
  pub fn new() -> Self {
    Self { kv: db() }
  }
}

impl DocumentUser for FakeUser {
  fn user_id(&self) -> Result<i64, flowy_error::FlowyError> {
    Ok(1)
  }

  fn token(&self) -> Result<Option<String>, flowy_error::FlowyError> {
    Ok(None)
  }

  fn collab_db(&self) -> Result<std::sync::Arc<RocksCollabDB>, flowy_error::FlowyError> {
    Ok(self.kv.clone())
  }
}

pub fn db() -> Arc<RocksCollabDB> {
  static START: Once = Once::new();
  START.call_once(|| {
    std::env::set_var("RUST_LOG", "collab_persistence=trace");
    let subscriber = Subscriber::builder()
      .with_env_filter(EnvFilter::from_default_env())
      .with_ansi(true)
      .finish();
    subscriber.try_init().unwrap();
  });

  let tempdir = TempDir::new().unwrap();
  let path = tempdir.into_path();
  Arc::new(RocksCollabDB::open(path).unwrap())
}

pub fn default_collab_builder() -> Arc<AppFlowyCollabBuilder> {
  let builder = AppFlowyCollabBuilder::new(CloudStorageType::Local, None);
  Arc::new(builder)
}
