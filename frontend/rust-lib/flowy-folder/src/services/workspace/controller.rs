use crate::{
    dart_notification::*,
    errors::*,
    event_map::{FolderCouldServiceV1, WorkspaceUser},
    services::{
        persistence::{FolderPersistence, FolderPersistenceTransaction, WorkspaceChangeset},
        read_local_workspace_apps, TrashController,
    },
};
use flowy_database::kv::KV;
use flowy_folder_data_model::entities::{app::RepeatedApp, workspace::*};
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
    ) -> Result<Workspace, FlowyError> {
        let workspace = self.create_workspace_on_server(params.clone()).await?;
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let workspaces = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.create_workspace(&user_id, workspace.clone())?;
                transaction.read_workspaces(&user_id, None)
            })
            .await?;
        let repeated_workspace = RepeatedWorkspace { items: workspaces };
        send_dart_notification(&token, FolderNotification::UserCreateWorkspace)
            .payload(repeated_workspace)
            .send();
        set_current_workspace(&workspace.id);
        Ok(workspace)
    }

    #[allow(dead_code)]
    pub(crate) async fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), FlowyError> {
        let changeset = WorkspaceChangeset::new(params.clone());
        let workspace_id = changeset.id.clone();
        let workspace = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.update_workspace(changeset)?;
                let user_id = self.user.user_id()?;
                self.read_local_workspace(workspace_id.clone(), &user_id, &transaction)
            })
            .await?;

        send_dart_notification(&workspace_id, FolderNotification::WorkspaceUpdated)
            .payload(workspace)
            .send();
        let _ = self.update_workspace_on_server(params)?;

        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let repeated_workspace = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.delete_workspace(workspace_id)?;
                self.read_local_workspaces(None, &user_id, &transaction)
            })
            .await?;
        send_dart_notification(&token, FolderNotification::UserDeleteWorkspace)
            .payload(repeated_workspace)
            .send();
        let _ = self.delete_workspace_on_server(workspace_id)?;
        Ok(())
    }

    pub(crate) async fn open_workspace(&self, params: WorkspaceId) -> Result<Workspace, FlowyError> {
        let user_id = self.user.user_id()?;
        if let Some(workspace_id) = params.workspace_id {
            let workspace = self
                .persistence
                .begin_transaction(|transaction| self.read_local_workspace(workspace_id, &user_id, &transaction))
                .await?;
            set_current_workspace(&workspace.id);
            Ok(workspace)
        } else {
            Err(FlowyError::workspace_id().context("Opened workspace id should not be empty"))
        }
    }

    pub(crate) async fn read_current_workspace_apps(&self) -> Result<RepeatedApp, FlowyError> {
        let workspace_id = get_current_workspace()?;
        let repeated_app = self
            .persistence
            .begin_transaction(|transaction| {
                read_local_workspace_apps(&workspace_id, self.trash_controller.clone(), &transaction)
            })
            .await?;
        // TODO: read from server
        Ok(repeated_app)
    }

    #[tracing::instrument(level = "debug", skip(self, transaction), err)]
    pub(crate) fn read_local_workspaces<'a>(
        &self,
        workspace_id: Option<String>,
        user_id: &str,
        transaction: &'a (dyn FolderPersistenceTransaction + 'a),
    ) -> Result<RepeatedWorkspace, FlowyError> {
        let workspace_id = workspace_id.to_owned();
        let workspaces = transaction.read_workspaces(user_id, workspace_id)?;
        Ok(RepeatedWorkspace { items: workspaces })
    }

    pub(crate) fn read_local_workspace<'a>(
        &self,
        workspace_id: String,
        user_id: &str,
        transaction: &'a (dyn FolderPersistenceTransaction + 'a),
    ) -> Result<Workspace, FlowyError> {
        let mut workspaces = transaction.read_workspaces(user_id, Some(workspace_id.clone()))?;
        if workspaces.is_empty() {
            return Err(FlowyError::record_not_found().context(format!("{} workspace not found", workspace_id)));
        }
        debug_assert_eq!(workspaces.len(), 1);
        let workspace = workspaces.drain(..1).collect::<Vec<Workspace>>().pop().unwrap();
        Ok(workspace)
    }
}

impl WorkspaceController {
    #[tracing::instrument(level = "trace", skip(self), err)]
    async fn create_workspace_on_server(&self, params: CreateWorkspaceParams) -> Result<Workspace, FlowyError> {
        let token = self.user.token()?;
        let workspace = self.cloud_service.create_workspace(&token, params).await?;
        Ok(workspace)
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    fn update_workspace_on_server(&self, params: UpdateWorkspaceParams) -> Result<(), FlowyError> {
        let (token, server) = (self.user.token()?, self.cloud_service.clone());
        tokio::spawn(async move {
            match server.update_workspace(&token, params).await {
                Ok(_) => {}
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update workspace failed: {:?}", e);
                }
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    fn delete_workspace_on_server(&self, workspace_id: &str) -> Result<(), FlowyError> {
        let params = WorkspaceId {
            workspace_id: Some(workspace_id.to_string()),
        };
        let (token, server) = (self.user.token()?, self.cloud_service.clone());
        tokio::spawn(async move {
            match server.delete_workspace(&token, params).await {
                Ok(_) => {}
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete workspace failed: {:?}", e);
                }
            }
        });
        Ok(())
    }
}

const CURRENT_WORKSPACE_ID: &str = "current_workspace_id";

pub fn set_current_workspace(workspace_id: &str) {
    KV::set_str(CURRENT_WORKSPACE_ID, workspace_id.to_owned());
}

pub fn get_current_workspace() -> Result<String, FlowyError> {
    match KV::get_str(CURRENT_WORKSPACE_ID) {
        None => {
            Err(FlowyError::record_not_found()
                .context("Current workspace not found or should call open workspace first"))
        }
        Some(workspace_id) => Ok(workspace_id),
    }
}
