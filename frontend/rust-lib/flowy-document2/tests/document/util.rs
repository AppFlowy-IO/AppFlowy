use std::ops::Deref;
use std::sync::Arc;

use anyhow::Error;
use appflowy_integrate::collab_builder::{AppFlowyCollabBuilder, DefaultCollabStorageProvider};
use appflowy_integrate::RocksCollabDB;
use bytes::Bytes;
use collab_document::blocks::DocumentData;
use collab_document::document_data::default_document_data;
use nanoid::nanoid;
use parking_lot::Once;
use tempfile::TempDir;
use tracing_subscriber::{fmt::Subscriber, util::SubscriberInitExt, EnvFilter};

use flowy_document2::document::MutexDocument;
use flowy_document2::manager::{DocumentManager, DocumentUser};
use flowy_document_deps::cloud::*;
use flowy_error::FlowyError;
use flowy_storage::{FileStorageService, StorageObject};
use lib_infra::future::FutureResult;

pub struct DocumentTest {
  inner: DocumentManager,
}

impl DocumentTest {
  pub fn new() -> Self {
    let user = FakeUser::new();
    let cloud_service = Arc::new(LocalTestDocumentCloudServiceImpl());
    let file_storage = Arc::new(DocumentTestFileStorageService) as Arc<dyn FileStorageService>;
    let manager = DocumentManager::new(
      Arc::new(user),
      default_collab_builder(),
      cloud_service,
      Arc::downgrade(&file_storage),
    );
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
  collab_db: Arc<RocksCollabDB>,
}

impl FakeUser {
  pub fn new() -> Self {
    Self { collab_db: db() }
  }
}

impl DocumentUser for FakeUser {
  fn user_id(&self) -> Result<i64, flowy_error::FlowyError> {
    Ok(1)
  }

  fn token(&self) -> Result<Option<String>, flowy_error::FlowyError> {
    Ok(None)
  }

  fn collab_db(
    &self,
    _uid: i64,
  ) -> Result<std::sync::Weak<RocksCollabDB>, flowy_error::FlowyError> {
    Ok(Arc::downgrade(&self.collab_db))
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
  let builder = AppFlowyCollabBuilder::new(DefaultCollabStorageProvider());
  builder.set_sync_device(uuid::Uuid::new_v4().to_string());
  Arc::new(builder)
}

pub async fn create_and_open_empty_document() -> (DocumentTest, Arc<MutexDocument>, String) {
  let test = DocumentTest::new();
  let doc_id: String = gen_document_id();
  let data = default_document_data();
  let uid = test.user.user_id().unwrap();
  // create a document
  _ = test
    .create_document(uid, &doc_id, Some(data.clone()))
    .await
    .unwrap();

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
  fn get_document_updates(&self, _document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_data(&self, _document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }
}

pub struct DocumentTestFileStorageService;
impl FileStorageService for DocumentTestFileStorageService {
  fn create_object(&self, _object: StorageObject) -> FutureResult<String, FlowyError> {
    todo!()
  }

  fn delete_object_by_url(&self, _object_url: String) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_object_by_url(&self, _object_url: String) -> FutureResult<Bytes, FlowyError> {
    todo!()
  }
}
