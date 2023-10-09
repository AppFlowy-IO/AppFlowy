use std::sync::Arc;

use anyhow::Context;

use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_database2::DatabaseManager;
use flowy_document2::manager::DocumentManager;
use flowy_error::FlowyResult;
use flowy_folder2::manager::{FolderInitializeDataSource, FolderManager};
use flowy_user::event_map::{UserCloudServiceProvider, UserStatusCallback};
use flowy_user_deps::cloud::UserCloudConfig;
use flowy_user_deps::entities::{AuthType, UserProfile, UserWorkspace};
use lib_infra::future::{to_fut, Fut};

use crate::integrate::server::ServerProvider;
use crate::AppFlowyCoreConfig;

pub(crate) struct UserStatusCallbackImpl {
  pub(crate) collab_builder: Arc<AppFlowyCollabBuilder>,
  pub(crate) folder_manager: Arc<FolderManager>,
  pub(crate) database_manager: Arc<DatabaseManager>,
  pub(crate) document_manager: Arc<DocumentManager>,
  pub(crate) server_provider: Arc<ServerProvider>,
  #[allow(dead_code)]
  pub(crate) config: AppFlowyCoreConfig,
}

impl UserStatusCallback for UserStatusCallbackImpl {
  fn auth_type_did_changed(&self, _auth_type: AuthType) {}

  fn did_init(
    &self,
    user_id: i64,
    cloud_config: &Option<UserCloudConfig>,
    user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    let user_id = user_id.to_owned();
    let user_workspace = user_workspace.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    if let Some(cloud_config) = cloud_config {
      self
        .server_provider
        .set_enable_sync(user_id, cloud_config.enable_sync);
      if cloud_config.enable_encrypt() {
        self
          .server_provider
          .set_encrypt_secret(cloud_config.encrypt_secret.clone());
      }
    }

    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize(
          user_id,
          &user_workspace.id,
          FolderInitializeDataSource::LocalDisk {
            create_if_not_exist: false,
          },
        )
        .await?;
      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_views_aggregate_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_sign_in(
    &self,
    user_id: i64,
    user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    let user_id = user_id.to_owned();
    let user_workspace = user_workspace.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      folder_manager
        .initialize_with_workspace_id(user_id, &user_workspace.id)
        .await?;
      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_views_aggregate_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_sign_up(
    &self,
    is_new_user: bool,
    user_profile: &UserProfile,
    user_workspace: &UserWorkspace,
    _device_id: &str,
  ) -> Fut<FlowyResult<()>> {
    let user_profile = user_profile.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let user_workspace = user_workspace.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      folder_manager
        .initialize_with_new_user(
          user_profile.uid,
          &user_profile.token,
          is_new_user,
          FolderInitializeDataSource::LocalDisk {
            create_if_not_exist: true,
          },
          &user_workspace.id,
        )
        .await
        .context("FolderManager error")?;

      database_manager
        .initialize_with_new_user(
          user_profile.uid,
          user_workspace.id.clone(),
          user_workspace.database_views_aggregate_id,
        )
        .await
        .context("DatabaseManager error")?;

      document_manager
        .initialize_with_new_user(user_profile.uid, user_workspace.id)
        .await
        .context("DocumentManager error")?;
      Ok(())
    })
  }

  fn did_expired(&self, _token: &str, user_id: i64) -> Fut<FlowyResult<()>> {
    let folder_manager = self.folder_manager.clone();
    to_fut(async move {
      folder_manager.clear(user_id).await;
      Ok(())
    })
  }

  fn open_workspace(&self, user_id: i64, user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>> {
    let user_workspace = user_workspace.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize_with_workspace_id(user_id, &user_workspace.id)
        .await?;

      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_views_aggregate_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_update_network(&self, reachable: bool) {
    self.collab_builder.update_network(reachable);
  }
}
