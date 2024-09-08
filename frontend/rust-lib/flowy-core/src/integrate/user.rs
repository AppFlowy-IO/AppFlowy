use std::sync::Arc;

use anyhow::Context;
use client_api::entity::billing_dto::SubscriptionPlan;
use tracing::{event, trace};

use collab_entity::CollabType;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_ai::ai_manager::AIManager;
use flowy_database2::DatabaseManager;
use flowy_document::manager::DocumentManager;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::{FolderInitDataSource, FolderManager};
use flowy_storage::manager::StorageManager;
use flowy_user::event_map::UserStatusCallback;
use flowy_user_pub::cloud::{UserCloudConfig, UserCloudServiceProvider};
use flowy_user_pub::entities::{Authenticator, UserProfile, UserWorkspace};
use lib_infra::async_trait::async_trait;

use crate::integrate::server::{Server, ServerProvider};

pub(crate) struct UserStatusCallbackImpl {
  pub(crate) collab_builder: Arc<AppFlowyCollabBuilder>,
  pub(crate) folder_manager: Arc<FolderManager>,
  pub(crate) database_manager: Arc<DatabaseManager>,
  pub(crate) document_manager: Arc<DocumentManager>,
  pub(crate) server_provider: Arc<ServerProvider>,
  pub(crate) storage_manager: Arc<StorageManager>,
  pub(crate) ai_manager: Arc<AIManager>,
}

#[async_trait]
impl UserStatusCallback for UserStatusCallbackImpl {
  async fn did_init(
    &self,
    user_id: i64,
    user_authenticator: &Authenticator,
    cloud_config: &Option<UserCloudConfig>,
    user_workspace: &UserWorkspace,
    _device_id: &str,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    self
      .server_provider
      .set_user_authenticator(user_authenticator);

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
        &user_workspace.id,
        FolderInitDataSource::LocalDisk {
          create_if_not_exist: false,
        },
      )
      .await?;
    self
      .database_manager
      .initialize(user_id, authenticator == &Authenticator::Local)
      .await?;
    self.document_manager.initialize(user_id).await?;
    self.ai_manager.initialize(&user_workspace.id).await?;
    Ok(())
  }

  async fn did_sign_in(
    &self,
    user_id: i64,
    user_workspace: &UserWorkspace,
    device_id: &str,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    event!(
      tracing::Level::TRACE,
      "Notify did sign in: latest_workspace: {:?}, device_id: {}",
      user_workspace,
      device_id
    );

    self
      .folder_manager
      .initialize_with_workspace_id(user_id)
      .await?;
    self
      .database_manager
      .initialize(user_id, authenticator.is_local())
      .await?;
    self.document_manager.initialize(user_id).await?;
    Ok(())
  }

  async fn did_sign_up(
    &self,
    is_new_user: bool,
    user_profile: &UserProfile,
    user_workspace: &UserWorkspace,
    device_id: &str,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    self
      .server_provider
      .set_user_authenticator(&user_profile.authenticator);
    let server_type = self.server_provider.get_server_type();

    event!(
      tracing::Level::TRACE,
      "Notify did sign up: is new: {} user_workspace: {:?}, device_id: {}",
      is_new_user,
      user_workspace,
      device_id
    );

    // In the current implementation, when a user signs up for AppFlowy Cloud, a default workspace
    // is automatically created for them. However, for users who sign up through Supabase, the creation
    // of the default workspace relies on the client-side operation. This means that the process
    // for initializing a default workspace differs depending on the sign-up method used.
    let data_source = match self
      .folder_manager
      .cloud_service
      .get_folder_doc_state(
        &user_workspace.id,
        user_profile.uid,
        CollabType::Folder,
        &user_workspace.id,
      )
      .await
    {
      Ok(doc_state) => match server_type {
        Server::Local => FolderInitDataSource::LocalDisk {
          create_if_not_exist: true,
        },
        Server::AppFlowyCloud => FolderInitDataSource::Cloud(doc_state),
      },
      Err(err) => match server_type {
        Server::Local => FolderInitDataSource::LocalDisk {
          create_if_not_exist: true,
        },
        Server::AppFlowyCloud => {
          return Err(FlowyError::from(err));
        },
      },
    };

    self
      .folder_manager
      .initialize_with_new_user(
        user_profile.uid,
        &user_profile.token,
        is_new_user,
        data_source,
        &user_workspace.id,
      )
      .await
      .context("FolderManager error")?;

    self
      .database_manager
      .initialize_with_new_user(user_profile.uid, authenticator.is_local())
      .await
      .context("DatabaseManager error")?;

    self
      .document_manager
      .initialize_with_new_user(user_profile.uid)
      .await
      .context("DocumentManager error")?;
    Ok(())
  }

  async fn did_expired(&self, _token: &str, user_id: i64) -> FlowyResult<()> {
    self.folder_manager.clear(user_id).await;
    Ok(())
  }

  async fn open_workspace(
    &self,
    user_id: i64,
    user_workspace: &UserWorkspace,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    self
      .folder_manager
      .initialize_with_workspace_id(user_id)
      .await?;
    self
      .database_manager
      .initialize(user_id, authenticator.is_local())
      .await?;
    self.document_manager.initialize(user_id).await?;
    self.ai_manager.initialize(&user_workspace.id).await?;
    self.storage_manager.initialize(&user_workspace.id).await;
    Ok(())
  }

  fn did_update_network(&self, reachable: bool) {
    trace!("Notify did update network: reachable: {}", reachable);
    self.collab_builder.update_network(reachable);
    self.storage_manager.update_network_reachable(reachable);
  }

  fn did_update_plans(&self, plans: Vec<SubscriptionPlan>) {
    let mut storage_plan_changed = false;
    let mut local_ai_enabled = false;
    for plan in &plans {
      match plan {
        SubscriptionPlan::Pro | SubscriptionPlan::Team => storage_plan_changed = true,
        SubscriptionPlan::AiLocal => local_ai_enabled = true,
        _ => {},
      }
    }
    if storage_plan_changed {
      self.storage_manager.enable_storage_write_access();
    }

    if local_ai_enabled {
      self.ai_manager.local_ai_purchased();
    }
  }

  fn did_update_storage_limitation(&self, can_write: bool) {
    if can_write {
      self.storage_manager.enable_storage_write_access();
    } else {
      self.storage_manager.disable_storage_write_access();
    }
  }
}
