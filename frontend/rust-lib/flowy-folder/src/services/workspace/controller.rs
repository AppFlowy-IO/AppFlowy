use crate::entities::workspace::*;
use crate::manager::FolderManager;
use crate::{
  errors::*,
  event_map::{FolderCouldServiceV1, WorkspaceUser},
  notification::*,
  services::{
    persistence::{FolderPersistence, FolderPersistenceTransaction, WorkspaceChangeset},
    read_workspace_apps, TrashController,
  },
};
use flowy_sqlite::kv::KV;
use folder_model::{AppRevision, WorkspaceRevision};
use lib_dispatch::prelude::ToBytes;
use std::sync::Arc;

pub struct WorkspaceController {
  pub user: Arc<dyn WorkspaceUser>,
  persistence: Arc<FolderPersistence>,
  pub(crate) trash_controller: Arc<TrashController>,
  cloud_service: Arc<dyn FolderCouldServiceV1>,
}

impl WorkspaceController {
  pub(crate) fn new(
    user: Arc<dyn WorkspaceUser>,
    persistence: Arc<FolderPersistence>,
    trash_can: Arc<TrashController>,
    cloud_service: Arc<dyn FolderCouldServiceV1>,
  ) -> Self {
    Self {
      user,
      persistence,
      trash_controller: trash_can,
      cloud_service,
    }
  }

  pub(crate) async fn create_workspace_from_params(
    &self,
    params: CreateWorkspaceParams,
  ) -> Result<WorkspaceRevision, FlowyError> {
    let workspace = self.create_workspace_on_server(params.clone()).await?;
    let user_id = self.user.user_id()?;
    let workspaces = self
      .persistence
      .begin_transaction(|transaction| {
        transaction.create_workspace(&user_id, workspace.clone())?;
        transaction.read_workspaces(&user_id, None)
      })
      .await?
      .into_iter()
      .map(|workspace_rev| workspace_rev.into())
      .collect();
    let repeated_workspace = RepeatedWorkspacePB { items: workspaces };
    send_workspace_notification(FolderNotification::DidCreateWorkspace, repeated_workspace);
    set_current_workspace(&user_id, &workspace.id);
    Ok(workspace)
  }

  #[allow(dead_code)]
  pub(crate) async fn update_workspace(
    &self,
    params: UpdateWorkspaceParams,
  ) -> Result<(), FlowyError> {
    let changeset = WorkspaceChangeset::new(params.clone());
    let workspace_id = changeset.id.clone();
    let workspace = self
      .persistence
      .begin_transaction(|transaction| {
        transaction.update_workspace(changeset)?;
        let user_id = self.user.user_id()?;
        self.read_workspace(workspace_id.clone(), &user_id, &transaction)
      })
      .await?;

    send_workspace_notification(FolderNotification::DidUpdateWorkspace, workspace);
    self.update_workspace_on_server(params)?;

    Ok(())
  }

  #[allow(dead_code)]
  pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
    let user_id = self.user.user_id()?;
    let repeated_workspace = self
      .persistence
      .begin_transaction(|transaction| {
        transaction.delete_workspace(workspace_id)?;
        self.read_workspaces(None, &user_id, &transaction)
      })
      .await?;

    send_workspace_notification(FolderNotification::DidDeleteWorkspace, repeated_workspace);
    self.delete_workspace_on_server(workspace_id)?;
    Ok(())
  }

  pub(crate) async fn open_workspace(
    &self,
    params: WorkspaceIdPB,
  ) -> Result<WorkspacePB, FlowyError> {
    let user_id = self.user.user_id()?;
    if let Some(workspace_id) = params.value {
      let workspace = self
        .persistence
        .begin_transaction(|transaction| self.read_workspace(workspace_id, &user_id, &transaction))
        .await?;
      set_current_workspace(&user_id, &workspace.id);
      Ok(workspace)
    } else {
      Err(FlowyError::workspace_id().context("Opened workspace id should not be empty"))
    }
  }

  pub(crate) async fn read_current_workspace_apps(&self) -> Result<Vec<AppRevision>, FlowyError> {
    let user_id = self.user.user_id()?;
    let workspace_id = get_current_workspace(&user_id)?;
    let app_revs = self
      .persistence
      .begin_transaction(|transaction| {
        read_workspace_apps(&workspace_id, self.trash_controller.clone(), &transaction)
      })
      .await?;
    // TODO: read from server
    Ok(app_revs)
  }

  #[tracing::instrument(level = "debug", skip(self, transaction), err)]
  pub(crate) fn read_workspaces<'a>(
    &self,
    workspace_id: Option<String>,
    user_id: &str,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
  ) -> Result<RepeatedWorkspacePB, FlowyError> {
    let workspace_id = workspace_id.to_owned();
    let trash_ids = self.trash_controller.read_trash_ids(transaction)?;
    let workspaces = transaction
      .read_workspaces(user_id, workspace_id)?
      .into_iter()
      .map(|mut workspace_rev| {
        workspace_rev
          .apps
          .retain(|app_rev| !trash_ids.contains(&app_rev.id));
        workspace_rev.into()
      })
      .collect();
    Ok(RepeatedWorkspacePB { items: workspaces })
  }

  pub(crate) fn read_workspace<'a>(
    &self,
    workspace_id: String,
    user_id: &str,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
  ) -> Result<WorkspacePB, FlowyError> {
    let mut workspaces = self
      .read_workspaces(Some(workspace_id.clone()), user_id, transaction)?
      .items;
    if workspaces.is_empty() {
      return Err(
        FlowyError::record_not_found().context(format!("{} workspace not found", workspace_id)),
      );
    }
    debug_assert_eq!(workspaces.len(), 1);
    let workspace = workspaces
      .drain(..1)
      .collect::<Vec<WorkspacePB>>()
      .pop()
      .unwrap();
    Ok(workspace)
  }
}

impl WorkspaceController {
  async fn create_workspace_on_server(
    &self,
    params: CreateWorkspaceParams,
  ) -> Result<WorkspaceRevision, FlowyError> {
    let token = self.user.token()?;
    self.cloud_service.create_workspace(&token, params).await
  }

  fn update_workspace_on_server(&self, params: UpdateWorkspaceParams) -> Result<(), FlowyError> {
    let (token, server) = (self.user.token()?, self.cloud_service.clone());
    tokio::spawn(async move {
      match server.update_workspace(&token, params).await {
        Ok(_) => {},
        Err(e) => {
          // TODO: retry?
          log::error!("Update workspace failed: {:?}", e);
        },
      }
    });
    Ok(())
  }

  fn delete_workspace_on_server(&self, workspace_id: &str) -> Result<(), FlowyError> {
    let params = WorkspaceIdPB {
      value: Some(workspace_id.to_string()),
    };
    let (token, server) = (self.user.token()?, self.cloud_service.clone());
    tokio::spawn(async move {
      match server.delete_workspace(&token, params).await {
        Ok(_) => {},
        Err(e) => {
          // TODO: retry?
          log::error!("Delete workspace failed: {:?}", e);
        },
      }
    });
    Ok(())
  }
}

pub async fn notify_workspace_setting_did_change(
  folder_manager: &Arc<FolderManager>,
  view_id: &str,
) -> FlowyResult<()> {
  let user_id = folder_manager.user.user_id()?;
  let workspace_id = get_current_workspace(&user_id)?;

  let workspace_setting = folder_manager
    .persistence
    .begin_transaction(|transaction| {
      let workspace = folder_manager.workspace_controller.read_workspace(
        workspace_id.clone(),
        &user_id,
        &transaction,
      )?;

      let setting = match transaction.read_view(view_id) {
        Ok(latest_view) => WorkspaceSettingPB {
          workspace,
          latest_view: Some(latest_view.into()),
        },
        Err(_) => WorkspaceSettingPB {
          workspace,
          latest_view: None,
        },
      };

      Ok(setting)
    })
    .await?;
  send_workspace_notification(
    FolderNotification::DidUpdateWorkspaceSetting,
    workspace_setting,
  );
  Ok(())
}

/// The [CURRENT_WORKSPACE] represents as the current workspace that opened by the
/// user. Only one workspace can be opened at a time.
const CURRENT_WORKSPACE: &str = "current-workspace";
fn send_workspace_notification<T: ToBytes>(ty: FolderNotification, payload: T) {
  send_notification(CURRENT_WORKSPACE, ty)
    .payload(payload)
    .send();
}

const CURRENT_WORKSPACE_ID: &str = "current_workspace_id";

pub fn set_current_workspace(_user_id: &str, workspace_id: &str) {
  KV::set_str(CURRENT_WORKSPACE_ID, workspace_id.to_owned());
}

pub fn clear_current_workspace(_user_id: &str) {
  let _ = KV::remove(CURRENT_WORKSPACE_ID);
}

pub fn get_current_workspace(_user_id: &str) -> Result<String, FlowyError> {
  match KV::get_str(CURRENT_WORKSPACE_ID) {
    None => Err(
      FlowyError::record_not_found()
        .context("Current workspace not found or should call open workspace first"),
    ),
    Some(workspace_id) => Ok(workspace_id),
  }
}
