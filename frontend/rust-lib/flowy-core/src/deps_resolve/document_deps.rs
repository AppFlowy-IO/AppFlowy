use std::sync::{Arc, Weak};

use crate::deps_resolve::CollabSnapshotSql;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_database2::DatabaseManager;
use flowy_document::entities::{DocumentSnapshotData, DocumentSnapshotMeta};
use flowy_document::manager::{DocumentManager, DocumentSnapshotService, DocumentUserService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::{FlowyError, FlowyResult};
use flowy_storage::ObjectStorageService;
use flowy_user::services::authenticate_user::AuthenticateUser;

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    _database_manager: &Arc<DatabaseManager>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn ObjectStorageService>,
  ) -> Arc<DocumentManager> {
    let user_service: Arc<dyn DocumentUserService> =
      Arc::new(DocumentUserImpl(authenticate_user.clone()));
    let snapshot_service = Arc::new(DocumentSnapshotImpl(authenticate_user));
    Arc::new(DocumentManager::new(
      user_service.clone(),
      collab_builder,
      cloud_service,
      storage_service,
      snapshot_service,
    ))
  }
}

struct DocumentSnapshotImpl(Weak<AuthenticateUser>);

impl DocumentSnapshotImpl {
  pub fn get_authenticate_user(&self) -> FlowyResult<Arc<AuthenticateUser>> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))
  }
}

impl DocumentSnapshotService for DocumentSnapshotImpl {
  fn get_document_snapshot_metas(
    &self,
    document_id: &str,
  ) -> FlowyResult<Vec<DocumentSnapshotMeta>> {
    let authenticate_user = self.get_authenticate_user()?;
    let uid = authenticate_user.user_id()?;
    let mut db = authenticate_user.get_sqlite_connection(uid)?;
    CollabSnapshotSql::get_all_snapshots(document_id, &mut db).map(|rows| {
      rows
        .into_iter()
        .map(|row| DocumentSnapshotMeta {
          snapshot_id: row.id,
          object_id: row.object_id,
          created_at: row.timestamp,
        })
        .collect()
    })
  }

  fn get_document_snapshot(&self, snapshot_id: &str) -> FlowyResult<DocumentSnapshotData> {
    let authenticate_user = self.get_authenticate_user()?;
    let uid = authenticate_user.user_id()?;
    let mut db = authenticate_user.get_sqlite_connection(uid)?;
    CollabSnapshotSql::get_snapshot(snapshot_id, &mut db)
      .map(|row| DocumentSnapshotData {
        object_id: row.id,
        encoded_v1: row.data,
      })
      .ok_or(
        FlowyError::record_not_found().with_context(format!("Snapshot {} not found", snapshot_id)),
      )
  }
}

struct DocumentUserImpl(Weak<AuthenticateUser>);
impl DocumentUserService for DocumentUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .user_id()
  }

  fn device_id(&self) -> Result<String, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .device_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .workspace_id()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .get_collab_db(uid)
  }
}
