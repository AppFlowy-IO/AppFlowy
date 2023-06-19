use appflowy_integrate::collab_builder::{AppFlowyCollabBuilder, CloudStorageType};

use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
use flowy_document2::document::Document;
use parking_lot::Once;
use tempfile::TempDir;
use tracing_subscriber::{fmt::Subscriber, util::SubscriberInitExt, EnvFilter};

use flowy_document2::document_data::default_document_data;
use flowy_document2::manager::{DocumentManager, DocumentUser};
use nanoid::nanoid;

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

pub fn create_and_open_empty_document() -> (DocumentManager, Arc<Document>, String) {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = gen_document_id();
  let data = default_document_data();

  // create a document
  _ = manager
    .create_document(&doc_id, Some(data.clone()))
    .unwrap();

  let document = manager.get_or_open_document(&doc_id).unwrap();

  (manager, document, data.page_id)
}

pub fn gen_document_id() -> String {
  let uuid = uuid::Uuid::new_v4();
  uuid.to_string()
}

pub fn gen_id() -> String {
  nanoid!(10)
}
