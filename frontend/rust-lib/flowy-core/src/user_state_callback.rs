use std::sync::Arc;

use anyhow::Context;
use client_api::entity::billing_dto::SubscriptionPlan;
use tracing::{error, event, info};

use crate::server_layer::ServerProvider;
use collab_entity::CollabType;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_ai::ai_manager::AIManager;
use flowy_database2::DatabaseManager;
use flowy_document::manager::DocumentManager;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::{FolderInitDataSource, FolderManager};
use flowy_storage::manager::StorageManager;
use flowy_user::event_map::UserStatusCallback;
use flowy_user::user_manager::UserManager;
use flowy_user_pub::cloud::{UserCloudConfig, UserCloudServiceProvider};
use flowy_user_pub::entities::{AuthType, UserProfile, UserWorkspace};
use lib_dispatch::runtime::AFPluginRuntime;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub(crate) struct UserStatusCallbackImpl {
  pub(crate) user_manager: Arc<UserManager>,
  pub(crate) collab_builder: Arc<AppFlowyCollabBuilder>,
  pub(crate) folder_manager: Arc<FolderManager>,
  pub(crate) database_manager: Arc<DatabaseManager>,
  pub(crate) document_manager: Arc<DocumentManager>,
  pub(crate) server_provider: Arc<ServerProvider>,
  pub(crate) storage_manager: Arc<StorageManager>,
  pub(crate) ai_manager: Arc<AIManager>,
  // By default, all callback will run on the caller thread. If you don't want to block the caller
  // thread, you can use runtime to spawn a new task.
  pub(crate) runtime: Arc<AFPluginRuntime>,
}

impl UserStatusCallbackImpl {
  async fn folder_init_data_source(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    auth_type: &AuthType,
  ) -> FlowyResult<FolderInitDataSource> {
    if self.is_object_exist_on_disk(user_id, workspace_id, workspace_id)? {
      return Ok(FolderInitDataSource::LocalDisk {
        create_if_not_exist: false,
      });
    }
    let doc_state_result = self
      .folder_manager
      .cloud_service
      .get_folder_doc_state(workspace_id, user_id, CollabType::Folder, workspace_id)
      .await;
    resolve_data_source(auth_type, doc_state_result)
  }

  fn is_object_exist_on_disk(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> FlowyResult<bool> {
    let db = self
      .user_manager
      .get_collab_db(user_id)?
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Collab db is not initialized"))?;
    let read = db.read_txn();
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    Ok(read.is_exist(user_id, &workspace_id, &object_id))
  }
}

#[async_trait]
impl UserStatusCallback for UserStatusCallbackImpl {
  async fn on_launch_if_authenticated(
    &self,
    user_id: i64,
    cloud_config: &Option<UserCloudConfig>,
    workspace_id: &Uuid,
    _device_id: &str,
    auth_type: &AuthType,
  ) -> FlowyResult<()> {
    if let Some(cloud_config) = cloud_config {
      self
        .server_provider
        .set_enable_sync(user_id, cloud_config.enable_sync);
      if cloud_config.enable_encrypt {
        self
          .server_provider
          .set_encrypt_secret(cloud_config.encrypt_secret.clone());
      }
    }

    self
      .folder_manager
      .initialize(
        user_id,
        workspace_id,
        FolderInitDataSource::LocalDisk {
          create_if_not_exist: false,
        },
      )
      .await?;
    self
      .database_manager
      .initialize(user_id, auth_type == &AuthType::Local)
      .await?;
    self.document_manager.initialize(user_id).await?;

    let cloned_ai_manager = self.ai_manager.clone();
    let workspace_id = *workspace_id;
    self.runtime.spawn(async move {
      if let Err(err) = cloned_ai_manager
        .on_launch_if_authenticated(&workspace_id)
        .await
      {
        error!("Failed to initialize AIManager: {:?}", err);
      }
    });
    Ok(())
  }

  async fn on_sign_in(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    device_id: &str,
    auth_type: &AuthType,
  ) -> FlowyResult<()> {
    event!(
      tracing::Level::TRACE,
      "Notify did sign in: latest_workspace: {:?}, device_id: {}",
      workspace_id,
      device_id
    );
    let data_source = self
      .folder_init_data_source(user_id, workspace_id, auth_type)
      .await?;
    self
      .folder_manager
      .initialize_after_sign_in(user_id, data_source)
      .await?;
    self
      .database_manager
      .initialize_after_sign_in(user_id, auth_type.is_local())
      .await?;
    self
      .document_manager
      .initialize_after_sign_in(user_id)
      .await?;

    self
      .ai_manager
      .initialize_after_sign_in(workspace_id)
      .await?;

    Ok(())
  }

  async fn on_sign_up(
    &self,
    is_new_user: bool,
    user_profile: &UserProfile,
    workspace_id: &Uuid,
    device_id: &str,
    auth_type: &AuthType,
  ) -> FlowyResult<()> {
    event!(
      tracing::Level::TRACE,
      "Notify did sign up: is new: {} user_workspace: {:?}, device_id: {}",
      is_new_user,
      workspace_id,
      device_id
    );
    let data_source = self
      .folder_init_data_source(user_profile.uid, workspace_id, auth_type)
      .await?;

    self
      .folder_manager
      .initialize_after_sign_up(
        user_profile.uid,
        &user_profile.token,
        is_new_user,
        data_source,
        workspace_id,
      )
      .await
      .context("FolderManager error")?;

    self
      .database_manager
      .initialize_after_sign_up(user_profile.uid, auth_type.is_local())
      .await
      .context("DatabaseManager error")?;

    self
      .document_manager
      .initialize_after_sign_up(user_profile.uid)
      .await
      .context("DocumentManager error")?;

    self
      .ai_manager
      .initialize_after_sign_up(workspace_id)
      .await?;
    Ok(())
  }

  async fn on_token_expired(&self, _token: &str, user_id: i64) -> FlowyResult<()> {
    self.folder_manager.clear(user_id).await;
    Ok(())
  }

  async fn on_workspace_opened(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    _user_workspace: &UserWorkspace,
    auth_type: &AuthType,
  ) -> FlowyResult<()> {
    let data_source = self
      .folder_init_data_source(user_id, workspace_id, auth_type)
      .await?;

    self
      .folder_manager
      .initialize_after_open_workspace(user_id, data_source)
      .await?;
    self
      .database_manager
      .initialize_after_open_workspace(user_id, auth_type.is_local())
      .await?;
    self
      .document_manager
      .initialize_after_open_workspace(user_id)
      .await?;
    self
      .ai_manager
      .initialize_after_open_workspace(workspace_id)
      .await?;
    self
      .storage_manager
      .initialize_after_open_workspace(workspace_id)
      .await;
    Ok(())
  }

  fn on_network_status_changed(&self, reachable: bool) {
    info!("Notify did update network: reachable: {}", reachable);
    self.collab_builder.update_network(reachable);
    self.storage_manager.update_network_reachable(reachable);
  }

  fn on_subscription_plans_updated(&self, plans: Vec<SubscriptionPlan>) {
    let mut storage_plan_changed = false;
    for plan in &plans {
      match plan {
        SubscriptionPlan::Pro | SubscriptionPlan::Team => storage_plan_changed = true,
        _ => {},
      }
    }
    if storage_plan_changed {
      self.storage_manager.enable_storage_write_access();
    }
  }

  fn on_storage_permission_updated(&self, can_write: bool) {
    if can_write {
      self.storage_manager.enable_storage_write_access();
    } else {
      self.storage_manager.disable_storage_write_access();
    }
  }
}

fn resolve_data_source(
  auth_type: &AuthType,
  doc_state_result: Result<Vec<u8>, FlowyError>,
) -> FlowyResult<FolderInitDataSource> {
  match doc_state_result {
    Ok(doc_state) => Ok(match auth_type {
      AuthType::Local => FolderInitDataSource::LocalDisk {
        create_if_not_exist: true,
      },
      AuthType::AppFlowyCloud => FolderInitDataSource::Cloud(doc_state),
    }),
    Err(err) => match auth_type {
      AuthType::Local => Ok(FolderInitDataSource::LocalDisk {
        create_if_not_exist: true,
      }),
      AuthType::AppFlowyCloud => Err(err),
    },
  }
}
