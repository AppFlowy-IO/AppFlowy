use std::sync::{Arc, Weak};

use crate::deps_resolve::CollabSnapshotSql;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_database2::DatabaseManager;
use flowy_document::entities::{DocumentSnapshotData, DocumentSnapshotMeta};
use flowy_document::manager::{DocumentManager, DocumentSnapshotService, DocumentUserService};
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{FlowyError, FlowyResult};
use flowy_storage::ObjectStorageService;
use flowy_user::manager::UserManager;

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
  pub fn resolve(
    user_manager: Weak<UserManager>,
    _database_manager: &Arc<DatabaseManager>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn ObjectStorageService>,
  ) -> Arc<DocumentManager> {
    let user_service: Arc<dyn DocumentUserService> =
      Arc::new(DocumentUserImpl(user_manager.clone()));
    let snapshot_service = Arc::new(DocumentSnapshotImpl(user_manager));
    Arc::new(DocumentManager::new(
      user_service.clone(),
      collab_builder,
      cloud_service,
      storage_service,
      snapshot_service,
    ))
  }
}

struct DocumentSnapshotImpl(Weak<UserManager>);

impl DocumentSnapshotImpl {
  pub fn get_user_manager(&self) -> FlowyResult<Arc<UserManager>> {
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
    let user_manager = self.get_user_manager()?;
    let uid = user_manager.user_id()?;
    let mut db = user_manager.db_connection(uid)?;
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
    let user_manager = self.get_user_manager()?;
    let uid = user_manager.user_id()?;
    let mut db = user_manager.db_connection(uid)?;
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

struct DocumentUserImpl(Weak<UserManager>);
impl DocumentUserService for DocumentUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .user_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .workspace_id()
  }

  fn token(&self) -> Result<Option<String>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .token()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .get_collab_db(uid)
  }
}
