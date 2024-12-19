use collab_entity::CollabType;
use flowy_ai::ai_manager::{AIExternalService, AIManager, AIUserService};
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_error::FlowyError;
use flowy_folder::ViewLayout;
use flowy_folder_pub::cloud::{FolderCloudService, FullSyncCollabParams};
use flowy_folder_pub::query::FolderQueryService;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;
use flowy_storage_pub::storage::StorageService;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_infra::async_trait::async_trait;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tracing::{error, info};

pub struct ChatDepsResolver;

impl ChatDepsResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    cloud_service: Arc<dyn ChatCloudService>,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
    folder_cloud_service: Arc<dyn FolderCloudService>,
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
        folder_cloud_service,
      },
    ))
  }
}

struct ChatQueryServiceImpl {
  folder_query: Box<dyn FolderQueryService>,
  folder_cloud_service: Arc<dyn FolderCloudService>,
}

#[async_trait]
impl AIExternalService for ChatQueryServiceImpl {
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

  async fn sync_rag_documents(
    &self,
    workspace_id: &str,
    rag_ids: Vec<String>,
  ) -> Result<(), FlowyError> {
    info!("sync_rag_documents: {:?}", rag_ids);

    for rag_id in rag_ids.iter() {
      if let Some(query_collab) = self
        .folder_query
        .get_collab(rag_id, CollabType::Document)
        .await
      {
        let params = FullSyncCollabParams {
          object_id: rag_id.clone(),
          collab_type: CollabType::Document,
          encoded_collab: query_collab.encoded_collab,
        };
        match self
          .folder_cloud_service
          .full_sync_collab_object(workspace_id, params)
          .await
        {
          Ok(_) => info!("[Chat] full sync rag document: {}", rag_id),
          Err(err) => error!("failed to sync rag document:{} error:{}", rag_id, err),
        }
      }
    }
    Ok(())
  }

  async fn notify_did_send_message(&self, chat_id: &str, message: &str) -> Result<(), FlowyError> {
    info!(
      "notify_did_send_message: chat_id: {}, message: {}",
      chat_id, message
    );
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
