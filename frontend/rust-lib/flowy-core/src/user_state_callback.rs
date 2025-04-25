use std::sync::{Arc, Weak};

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
use flowy_user_pub::entities::{UserProfile, UserWorkspace, WorkspaceType};
use lib_dispatch::runtime::AFPluginRuntime;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub(crate) struct UserStatusCallbackImpl {
  pub(crate) user_manager: Weak<UserManager>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
  pub(crate) folder_manager: Weak<FolderManager>,
  pub(crate) database_manager: Weak<DatabaseManager>,
  pub(crate) document_manager: Weak<DocumentManager>,
  pub(crate) server_provider: Weak<ServerProvider>,
  pub(crate) storage_manager: Weak<StorageManager>,
  pub(crate) ai_manager: Weak<AIManager>,
  // By default, all callback will run on the caller thread. If you don't want to block the caller
  // thread, you can use runtime to spawn a new task.
  pub(crate) runtime: Arc<AFPluginRuntime>,
}

impl UserStatusCallbackImpl {
  fn user_manager(&self) -> Result<Arc<UserManager>, FlowyError> {
    self.user_manager.upgrade().ok_or_else(FlowyError::ref_drop)
  }

  fn folder_manager(&self) -> Result<Arc<FolderManager>, FlowyError> {
    self
      .folder_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  fn database_manager(&self) -> Result<Arc<DatabaseManager>, FlowyError> {
    self
      .database_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  fn document_manager(&self) -> Result<Arc<DocumentManager>, FlowyError> {
    self
      .document_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  fn server_provider(&self) -> Result<Arc<ServerProvider>, FlowyError> {
    self
      .server_provider
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  fn storage_manager(&self) -> Result<Arc<StorageManager>, FlowyError> {
    self
      .storage_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  fn ai_manager(&self) -> Result<Arc<AIManager>, FlowyError> {
    self.ai_manager.upgrade().ok_or_else(FlowyError::ref_drop)
  }

  async fn folder_init_data_source(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<FolderInitDataSource> {
    if self.is_object_exist_on_disk(user_id, workspace_id, workspace_id)? {
      return Ok(FolderInitDataSource::LocalDisk {
        create_if_not_exist: false,
      });
    }
    let doc_state_result = self
      .folder_manager()?
      .cloud_service()?
      .get_folder_doc_state(workspace_id, user_id, CollabType::Folder, workspace_id)
      .await;
    resolve_data_source(workspace_type, doc_state_result)
  }

  fn is_object_exist_on_disk(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> FlowyResult<bool> {
    let db = self
      .user_manager()?
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
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<()> {
    if let Some(cloud_config) = cloud_config {
      self
        .server_provider()?
        .set_enable_sync(user_id, cloud_config.enable_sync);
      if cloud_config.enable_encrypt {
        self
          .server_provider()?
          .set_encrypt_secret(cloud_config.encrypt_secret.clone());
      }
    }

    self
      .folder_manager()?
      .initialize(
        user_id,
        workspace_id,
        FolderInitDataSource::LocalDisk {
          create_if_not_exist: false,
        },
      )
      .await?;
    self
      .database_manager()?
      .initialize(user_id, workspace_type == &WorkspaceType::Local)
      .await?;
    self.document_manager()?.initialize(user_id).await?;

    let cloned_ai_manager = self.ai_manager()?;
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
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<()> {
    event!(
      tracing::Level::TRACE,
      "Notify did sign in: latest_workspace: {:?}, device_id: {}",
      workspace_id,
      device_id
    );
    let data_source = self
      .folder_init_data_source(user_id, workspace_id, workspace_type)
      .await?;
    self
      .folder_manager()?
      .initialize_after_sign_in(user_id, data_source)
      .await?;
    self
      .database_manager()?
      .initialize_after_sign_in(user_id, workspace_type.is_local())
      .await?;
    self
      .document_manager()?
      .initialize_after_sign_in(user_id)
      .await?;

    self
      .ai_manager()?
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
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<()> {
    event!(
      tracing::Level::TRACE,
      "Notify did sign up: is new: {} user_workspace: {:?}, device_id: {}",
      is_new_user,
      workspace_id,
      device_id
    );
    let data_source = self
      .folder_init_data_source(user_profile.uid, workspace_id, workspace_type)
      .await?;

    self
      .folder_manager()?
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
      .database_manager()?
      .initialize_after_sign_up(user_profile.uid, workspace_type.is_local())
      .await
      .context("DatabaseManager error")?;

    self
      .document_manager()?
      .initialize_after_sign_up(user_profile.uid)
      .await
      .context("DocumentManager error")?;

    self
      .ai_manager()?
      .initialize_after_sign_up(workspace_id)
      .await?;
    Ok(())
  }

  async fn on_token_expired(&self, _token: &str, user_id: i64) -> FlowyResult<()> {
    self.folder_manager()?.clear(user_id).await;
    Ok(())
  }

  async fn on_workspace_opened(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    _user_workspace: &UserWorkspace,
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<()> {
    let data_source = self
      .folder_init_data_source(user_id, workspace_id, workspace_type)
      .await?;

    self
      .folder_manager()?
      .initialize_after_open_workspace(user_id, data_source)
      .await?;
    self
      .database_manager()?
      .initialize_after_open_workspace(user_id, workspace_type.is_local())
      .await?;
    self
      .document_manager()?
      .initialize_after_open_workspace(user_id)
      .await?;
    self
      .ai_manager()?
      .initialize_after_open_workspace(workspace_id)
      .await?;
    self
      .storage_manager()?
      .initialize_after_open_workspace(workspace_id)
      .await;
    Ok(())
  }

  fn on_network_status_changed(&self, reachable: bool) {
    info!("Notify did update network: reachable: {}", reachable);
    if let Some(collab_builder) = self.collab_builder.upgrade() {
      collab_builder.update_network(reachable);
    }

    if let Ok(storage) = self.storage_manager() {
      storage.update_network_reachable(reachable);
    }
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
      if let Ok(storage) = self.storage_manager() {
        storage.enable_storage_write_access();
      }
    }
  }

  fn on_storage_permission_updated(&self, can_write: bool) {
    if let Ok(storage) = self.storage_manager() {
      if can_write {
        storage.enable_storage_write_access();
      } else {
        storage.disable_storage_write_access();
      }
    }
  }
}

fn resolve_data_source(
  workspace_type: &WorkspaceType,
  doc_state_result: Result<Vec<u8>, FlowyError>,
) -> FlowyResult<FolderInitDataSource> {
  match doc_state_result {
    Ok(doc_state) => Ok(match workspace_type {
      WorkspaceType::Local => FolderInitDataSource::LocalDisk {
        create_if_not_exist: true,
      },
      WorkspaceType::Server => FolderInitDataSource::Cloud(doc_state),
    }),
    Err(err) => match workspace_type {
      WorkspaceType::Local => Ok(FolderInitDataSource::LocalDisk {
        create_if_not_exist: true,
      }),
      WorkspaceType::Server => Err(err),
    },
  }
}
