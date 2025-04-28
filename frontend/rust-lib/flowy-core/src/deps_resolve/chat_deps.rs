use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::{Collab, StateVector};
use collab::util::is_change_since_sv;
use collab_entity::CollabType;
use flowy_ai::ai_manager::{AIExternalService, AIManager};
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_ai_pub::persistence::AFCollabMetadata;
use flowy_ai_pub::user_service::AIUserService;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::ViewLayout;
use flowy_folder_pub::cloud::{FolderCloudService, FullSyncCollabParams};
use flowy_folder_pub::query::FolderService;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;
use flowy_storage_pub::storage::StorageService;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tracing::{error, info};
use uuid::Uuid;

pub struct ChatDepsResolver;

impl ChatDepsResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    cloud_service: Arc<dyn ChatCloudService>,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
    folder_cloud_service: Arc<dyn FolderCloudService>,
    folder_service: impl FolderService,
    local_ai: Arc<LocalAIController>,
  ) -> Arc<AIManager> {
    let user_service = ChatUserServiceImpl(authenticate_user);
    Arc::new(AIManager::new(
      cloud_service,
      user_service,
      store_preferences,
      storage_service,
      ChatQueryServiceImpl {
        folder_service: Box::new(folder_service),
        folder_cloud_service,
      },
      local_ai,
    ))
  }
}

struct ChatQueryServiceImpl {
  folder_service: Box<dyn FolderService>,
  folder_cloud_service: Arc<dyn FolderCloudService>,
}

#[async_trait]
impl AIExternalService for ChatQueryServiceImpl {
  async fn query_chat_rag_ids(
    &self,
    parent_view_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<Vec<Uuid>, FlowyError> {
    let mut ids = self
      .folder_service
      .get_surrounding_view_ids_with_view_layout(parent_view_id, ViewLayout::Document)
      .await;

    if !ids.is_empty() {
      ids.retain(|id| id != chat_id);
    }

    Ok(ids)
  }
  async fn sync_rag_documents(
    &self,
    workspace_id: &Uuid,
    rag_ids: Vec<Uuid>,
    mut rag_metadata_map: HashMap<Uuid, AFCollabMetadata>,
  ) -> Result<Vec<AFCollabMetadata>, FlowyError> {
    let mut result = Vec::new();

    for rag_id in rag_ids {
      // Retrieve the collab object for the current rag_id
      let query_collab = match self
        .folder_service
        .get_collab(&rag_id, CollabType::Document)
        .await
      {
        Some(collab) => collab,
        None => {
          continue;
        },
      };

      // Check if the state vector exists and detect changes
      if let Some(metadata) = rag_metadata_map.remove(&rag_id) {
        if let Ok(prev_sv) = StateVector::decode_v1(&metadata.prev_sync_state_vector) {
          let collab = Collab::new_with_source(
            CollabOrigin::Empty,
            &rag_id.to_string(),
            DataSource::DocStateV1(query_collab.encoded_collab.doc_state.to_vec()),
            vec![],
            false,
          )?;

          if !is_change_since_sv(&collab, &prev_sv) {
            info!("[Chat] no change since sv: {}", rag_id);
            continue;
          }
        }
      }

      // Perform full sync if changes are detected or no state vector is found
      let params = FullSyncCollabParams {
        object_id: rag_id,
        collab_type: CollabType::Document,
        encoded_collab: query_collab.encoded_collab.clone(),
      };

      if let Err(err) = self
        .folder_cloud_service
        .full_sync_collab_object(workspace_id, params)
        .await
      {
        error!("Failed to sync rag document: {} error: {}", rag_id, err);
      } else {
        info!("[Chat] full sync rag document: {}", rag_id);
        result.push(AFCollabMetadata {
          object_id: rag_id.to_string(),
          updated_at: timestamp(),
          prev_sync_state_vector: query_collab.encoded_collab.state_vector.to_vec(),
          collab_type: CollabType::Document as i32,
        });
      }
    }

    Ok(result)
  }

  async fn notify_did_send_message(&self, chat_id: &Uuid, message: &str) -> Result<(), FlowyError> {
    info!(
      "notify_did_send_message: chat_id: {}, message: {}",
      chat_id, message
    );
    self
      .folder_service
      .set_view_title_if_empty(chat_id, message)
      .await?;
    Ok(())
  }
}

pub struct ChatUserServiceImpl(Weak<AuthenticateUser>);
impl ChatUserServiceImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

#[async_trait]
impl AIUserService for ChatUserServiceImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  async fn is_local_model(&self) -> FlowyResult<bool> {
    self.upgrade_user()?.is_local_mode().await
  }

  fn workspace_id(&self) -> Result<Uuid, FlowyError> {
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
