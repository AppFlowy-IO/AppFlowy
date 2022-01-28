use crate::services::{
    folder_editor::FolderEditor,
    persistence::{AppChangeset, FolderPersistenceTransaction, ViewChangeset, WorkspaceChangeset},
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_data_model::entities::{
    app::App,
    trash::{RepeatedTrash, Trash},
    view::View,
    workspace::Workspace,
};
use std::sync::Arc;

impl FolderPersistenceTransaction for FolderEditor {
    fn create_workspace(&self, _user_id: &str, workspace: Workspace) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_workspace(workspace)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_workspaces(&self, _user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>> {
        let workspaces = self.folder.read().read_workspaces(workspace_id)?;
        Ok(workspaces)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder
            .write()
            .update_workspace(&changeset.id, changeset.name, changeset.desc)?
        {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().delete_workspace(workspace_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_app(&self, app: App) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_app(app)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder
            .write()
            .update_app(&changeset.id, changeset.name, changeset.desc)?
        {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<App> {
        let app = self.folder.read().read_app(app_id)?;
        Ok(app)
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>> {
        let workspaces = self.folder.read().read_workspaces(Some(workspace_id.to_owned()))?;
        match workspaces.first() {
            None => {
                Err(FlowyError::record_not_found().context(format!("can't find workspace with id {}", workspace_id)))
            }
            Some(workspace) => Ok(workspace.apps.clone().take_items()),
        }
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<App> {
        let app = self.folder.read().read_app(app_id)?;
        if let Some(change) = self.folder.write().delete_app(app_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(app)
    }

    fn create_view(&self, view: View) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_view(view)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<View> {
        let view = self.folder.read().read_view(view_id)?;
        Ok(view)
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>> {
        let views = self.folder.read().read_views(belong_to_id)?;
        Ok(views)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        if let Some(change) =
            self.folder
                .write()
                .update_view(&changeset.id, changeset.name, changeset.desc, changeset.modified_time)?
        {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().delete_view(view_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_trash(trashes)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash> {
        let trash = self.folder.read().read_trash(trash_id)?;
        Ok(RepeatedTrash { items: trash })
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().delete_trash(trash_ids)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }
}

impl<T> FolderPersistenceTransaction for Arc<T>
where
    T: FolderPersistenceTransaction + ?Sized,
{
    fn create_workspace(&self, user_id: &str, workspace: Workspace) -> FlowyResult<()> {
        (**self).create_workspace(user_id, workspace)
    }

    fn read_workspaces(&self, user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>> {
        (**self).read_workspaces(user_id, workspace_id)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        (**self).update_workspace(changeset)
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        (**self).delete_workspace(workspace_id)
    }

    fn create_app(&self, app: App) -> FlowyResult<()> {
        (**self).create_app(app)
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        (**self).update_app(changeset)
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<App> {
        (**self).read_app(app_id)
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>> {
        (**self).read_workspace_apps(workspace_id)
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<App> {
        (**self).delete_app(app_id)
    }

    fn create_view(&self, view: View) -> FlowyResult<()> {
        (**self).create_view(view)
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<View> {
        (**self).read_view(view_id)
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>> {
        (**self).read_views(belong_to_id)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        (**self).update_view(changeset)
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
        (**self).delete_view(view_id)
    }

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()> {
        (**self).create_trash(trashes)
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash> {
        (**self).read_trash(trash_id)
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        (**self).delete_trash(trash_ids)
    }
}
