use std::ops::Deref;
use std::sync::Arc;

use appflowy_integrate::collab_builder::{AppFlowyCollabBuilder, DefaultCollabStorageProvider};
use appflowy_integrate::RocksCollabDB;
use collab_document::blocks::DocumentData;
use nanoid::nanoid;
use parking_lot::Once;
use tempfile::TempDir;
use tracing_subscriber::{fmt::Subscriber, util::SubscriberInitExt, EnvFilter};

use flowy_document2::deps::{DocumentCloudService, DocumentSnapshot, DocumentUser};
use flowy_document2::document::MutexDocument;
use flowy_document2::document_data::default_document_data;
use flowy_document2::manager::DocumentManager;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub struct DocumentTest {
  inner: DocumentManager,
}

impl DocumentTest {
  pub fn new() -> Self {
    let user = FakeUser::new();
    let cloud_service = Arc::new(LocalTestDocumentCloudServiceImpl());
    let manager = DocumentManager::new(Arc::new(user), default_collab_builder(), cloud_service);
    Self { inner: manager }
  }
}

impl Deref for DocumentTest {
  type Target = DocumentManager;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

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

  fn collab_db(&self, _uid: i64) -> Result<std::sync::Arc<RocksCollabDB>, flowy_error::FlowyError> {
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
  let builder = AppFlowyCollabBuilder::new(DefaultCollabStorageProvider(), None);
  Arc::new(builder)
}

pub async fn create_and_open_empty_document() -> (DocumentTest, Arc<MutexDocument>, String) {
  let test = DocumentTest::new();
  let doc_id: String = gen_document_id();
  let data = default_document_data();

  // create a document
  _ = test.create_document(&doc_id, Some(data.clone())).unwrap();

  let document = test.get_document(&doc_id).await.unwrap();

  (test, document, data.page_id)
}

pub fn gen_document_id() -> String {
  let uuid = uuid::Uuid::new_v4();
  uuid.to_string()
}

pub fn gen_id() -> String {
  nanoid!(10)
}

pub struct LocalTestDocumentCloudServiceImpl();
impl DocumentCloudService for LocalTestDocumentCloudServiceImpl {
  fn get_document_updates(&self, _document_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_latest_snapshot(
    &self,
    _document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_document_data(
    &self,
    _document_id: &str,
  ) -> FutureResult<Option<DocumentData>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
