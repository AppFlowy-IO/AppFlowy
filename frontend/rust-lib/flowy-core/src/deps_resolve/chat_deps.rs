use flowy_ai::ai_manager::{AIManager, AIQueryService, AIUserService};
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_error::FlowyError;
use flowy_folder::ViewLayout;
use flowy_folder_pub::query::FolderQueryService;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;
use flowy_storage_pub::storage::StorageService;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_infra::async_trait::async_trait;
use std::path::PathBuf;
use std::sync::{Arc, Weak};

pub struct ChatDepsResolver;

impl ChatDepsResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    cloud_service: Arc<dyn ChatCloudService>,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
    folder_query: impl FolderQueryService,
  ) -> Arc<AIManager> {
    let user_service = ChatUserServiceImpl(authenticate_user);
    Arc::new(AIManager::new(
      cloud_service,
      user_service,
      store_preferences,
      storage_service,
      ChatQueryServiceImpl {
        folder_query: Box::new(folder_query),
      },
    ))
  }
}

struct ChatQueryServiceImpl {
  folder_query: Box<dyn FolderQueryService>,
}

#[async_trait]
impl AIQueryService for ChatQueryServiceImpl {
  async fn query_chat_rag_ids(
    &self,
    parent_view_id: &str,
    chat_id: &str,
  ) -> Result<Vec<String>, FlowyError> {
    let mut ids = self
      .folder_query
      .get_sibling_ids_with_view_layout(parent_view_id, ViewLayout::Document)
      .await;

    if !ids.is_empty() {
      ids.retain(|id| id != chat_id);
    }

    Ok(ids)
  }

  async fn sync_rag_documents(&self, rag_ids: Vec<String>) -> Result<(), FlowyError> {
    for rag_id in rag_ids.iter() {
      if let Some(_query_collab) = self.folder_query.get_collab(rag_id).await {
        // TODO(nathan): sync
      }
    }
    Ok(())
  }
}

struct ChatUserServiceImpl(Weak<AuthenticateUser>);
impl ChatUserServiceImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl AIUserService for ChatUserServiceImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn device_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.device_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.upgrade_user()?.get_sqlite_connection(uid)
  }

  fn application_root_dir(&self) -> Result<PathBuf, FlowyError> {
    Ok(PathBuf::from(
      self.upgrade_user()?.get_application_root_dir(),
    ))
  }
}
