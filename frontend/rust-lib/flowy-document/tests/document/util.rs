use std::ops::Deref;
use std::sync::Arc;

use anyhow::Error;
use collab::preclude::CollabPlugin;
use collab_document::blocks::DocumentData;
use collab_document::document_data::default_document_data;
use nanoid::nanoid;
use parking_lot::Once;
use tempfile::TempDir;
use tracing_subscriber::{fmt::Subscriber, util::SubscriberInitExt, EnvFilter};
use uuid::Uuid;

use collab_integrate::collab_builder::{
  AppFlowyCollabBuilder, CollabCloudPluginProvider, CollabPluginProviderContext,
  CollabPluginProviderType,
};
use collab_integrate::CollabKVDB;
use flowy_document::document::MutexDocument;
use flowy_document::entities::{DocumentSnapshotData, DocumentSnapshotMeta};
use flowy_document::manager::{DocumentManager, DocumentSnapshotService, DocumentUserService};
use flowy_document_pub::cloud::*;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_storage::ObjectStorageService;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub struct DocumentTest {
  inner: DocumentManager,
}

impl DocumentTest {
  pub fn new() -> Self {
    let user = FakeUser::new();
    let cloud_service = Arc::new(LocalTestDocumentCloudServiceImpl());
    let file_storage = Arc::new(DocumentTestFileStorageService) as Arc<dyn ObjectStorageService>;
    let document_snapshot = Arc::new(DocumentTestSnapshot);
    let manager = DocumentManager::new(
      Arc::new(user),
      default_collab_builder(),
      cloud_service,
      Arc::downgrade(&file_storage),
      document_snapshot,
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
  collab_db: Arc<CollabKVDB>,
}

impl FakeUser {
  pub fn new() -> Self {
    setup_log();

    let tempdir = TempDir::new().unwrap();
    let path = tempdir.into_path();
    let collab_db = Arc::new(CollabKVDB::open(path).unwrap());

    Self { collab_db }
  }
}

impl DocumentUserService for FakeUser {
  fn user_id(&self) -> Result<i64, FlowyError> {
    Ok(1)
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    Ok(Uuid::new_v4().to_string())
  }

  fn collab_db(&self, _uid: i64) -> Result<std::sync::Weak<CollabKVDB>, FlowyError> {
    Ok(Arc::downgrade(&self.collab_db))
  }
}

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    std::env::set_var("RUST_LOG", "collab_persistence=trace");
    let subscriber = Subscriber::builder()
      .with_env_filter(EnvFilter::from_default_env())
      .with_ansi(true)
      .finish();
    subscriber.try_init().unwrap();
  });
}

pub fn default_collab_builder() -> Arc<AppFlowyCollabBuilder> {
  let builder =
    AppFlowyCollabBuilder::new(DefaultCollabStorageProvider(), "fake_device_id".to_string());
  builder.initialize(uuid::Uuid::new_v4().to_string());
  Arc::new(builder)
}

pub async fn create_and_open_empty_document() -> (DocumentTest, Arc<MutexDocument>, String) {
  let test = DocumentTest::new();
  let doc_id: String = gen_document_id();
  let data = default_document_data();
  let uid = test.user_service.user_id().unwrap();
  // create a document
  test
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
  fn get_document_doc_state(
    &self,
    document_id: &str,
    _workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        format!("Document {} not found", document_id),
      ))
    })
  }

  fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
    _workspace_id: &str,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_data(
    &self,
    _document_id: &str,
    _workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }
}

pub struct DocumentTestFileStorageService;
impl ObjectStorageService for DocumentTestFileStorageService {
  fn get_object_url(
    &self,
    _object_id: flowy_storage::ObjectIdentity,
  ) -> FutureResult<String, FlowyError> {
    todo!()
  }

  fn put_object(
    &self,
    _url: String,
    _object_value: flowy_storage::ObjectValue,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn delete_object(&self, _url: String) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_object(&self, _url: String) -> FutureResult<flowy_storage::ObjectValue, FlowyError> {
    todo!()
  }
}

struct DefaultCollabStorageProvider();

#[async_trait]
impl CollabCloudPluginProvider for DefaultCollabStorageProvider {
  fn provider_type(&self) -> CollabPluginProviderType {
    CollabPluginProviderType::Local
  }

  fn get_plugins(&self, _context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>> {
    vec![]
  }

  fn is_sync_enabled(&self) -> bool {
    false
  }
}

struct DocumentTestSnapshot;
impl DocumentSnapshotService for DocumentTestSnapshot {
  fn get_document_snapshot_metas(
    &self,
    _document_id: &str,
  ) -> FlowyResult<Vec<DocumentSnapshotMeta>> {
    todo!()
  }

  fn get_document_snapshot(&self, _snapshot_id: &str) -> FlowyResult<DocumentSnapshotData> {
    todo!()
  }
}
