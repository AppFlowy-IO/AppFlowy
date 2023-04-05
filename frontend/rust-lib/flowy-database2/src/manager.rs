use crate::entities::DatabaseLayoutPB;
use crate::services::database::DatabaseEditor;
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseUser2: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError>;
}

pub struct DatabaseManager2 {
  database_user: Arc<dyn DatabaseUser2>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  editors: RwLock<HashMap<String, Arc<DatabaseEditor>>>,
}

impl DatabaseManager2 {
  pub fn new(
    database_user: Arc<dyn DatabaseUser2>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> Self {
    Self {
      database_user,
      task_scheduler,
      editors: Default::default(),
    }
  }

  pub async fn initialize_with_new_user(&self, _user_id: i64, _token: &str) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn initialize(
    &self,
    _user_id: i64,
    _token: &str,
    _get_views_fn: Fut<Vec<(String, String, DatabaseLayoutPB)>>,
  ) -> FlowyResult<()> {
    Ok(())
  }
}
