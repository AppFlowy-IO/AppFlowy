use crate::services::{
    folder_editor::FolderEditor,
    persistence::{AppChangeset, FolderPersistenceTransaction, ViewChangeset, WorkspaceChangeset},
};
use flowy_error::{FlowyError, FlowyResult};
use folder_rev_model::{AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
use std::sync::Arc;

impl FolderPersistenceTransaction for FolderEditor {
    fn create_workspace(&self, _user_id: &str, workspace_rev: WorkspaceRevision) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_workspace(workspace_rev)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_workspaces(&self, _user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<WorkspaceRevision>> {
        let workspaces = self.folder.read().read_workspaces(workspace_id)?;
        Ok(workspaces)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder
            .write()
            .update_workspace(&changeset.id, changeset.name, changeset.desc)?
        {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().delete_workspace(workspace_id)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_app(&self, app_rev: AppRevision) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_app(app_rev)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder
            .write()
            .update_app(&changeset.id, changeset.name, changeset.desc)?
        {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<AppRevision> {
        let app = self.folder.read().read_app(app_id)?;
        Ok(app)
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<AppRevision>> {
        let workspaces = self.folder.read().read_workspaces(Some(workspace_id.to_owned()))?;
        match workspaces.first() {
            None => {
                Err(FlowyError::record_not_found().context(format!("can't find workspace with id {}", workspace_id)))
            }
            Some(workspace) => Ok(workspace.apps.clone()),
        }
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<AppRevision> {
        let app = self.folder.read().read_app(app_id)?;
        if let Some(change) = self.folder.write().delete_app(app_id)? {
            self.apply_change(change)?;
        }
        Ok(app)
    }

    fn move_app(&self, app_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().move_app(app_id, from, to)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_view(&self, view_rev: ViewRevision) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_view(view_rev)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<ViewRevision> {
        let view = self.folder.read().read_view(view_id)?;
        Ok(view)
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<ViewRevision>> {
        let views = self.folder.read().read_views(belong_to_id)?;
        Ok(views)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        if let Some(change) =
            self.folder
                .write()
                .update_view(&changeset.id, changeset.name, changeset.desc, changeset.modified_time)?
        {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<ViewRevision> {
        let view = self.folder.read().read_view(view_id)?;
        if let Some(change) = self.folder.write().delete_view(&view.app_id, view_id)? {
            self.apply_change(change)?;
        }
        Ok(view)
    }

    fn move_view(&self, view_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().move_view(view_id, from, to)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_trash(&self, trashes: Vec<TrashRevision>) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().create_trash(trashes)? {
            self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<Vec<TrashRevision>> {
        let trash = self.folder.read().read_trash(trash_id)?;
        Ok(trash)
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        if let Some(change) = self.folder.write().delete_trash(trash_ids)? {
            self.apply_change(change)?;
        }
        Ok(())
    }
}

impl<T> FolderPersistenceTransaction for Arc<T>
where
    T: FolderPersistenceTransaction + ?Sized,
{
    fn create_workspace(&self, user_id: &str, workspace_rev: WorkspaceRevision) -> FlowyResult<()> {
        (**self).create_workspace(user_id, workspace_rev)
    }

    fn read_workspaces(&self, user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<WorkspaceRevision>> {
        (**self).read_workspaces(user_id, workspace_id)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        (**self).update_workspace(changeset)
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        (**self).delete_workspace(workspace_id)
    }

    fn create_app(&self, app_rev: AppRevision) -> FlowyResult<()> {
        (**self).create_app(app_rev)
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        (**self).update_app(changeset)
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<AppRevision> {
        (**self).read_app(app_id)
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<AppRevision>> {
        (**self).read_workspace_apps(workspace_id)
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<AppRevision> {
        (**self).delete_app(app_id)
    }

    fn move_app(&self, app_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        (**self).move_app(app_id, from, to)
    }

    fn create_view(&self, view_rev: ViewRevision) -> FlowyResult<()> {
        (**self).create_view(view_rev)
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<ViewRevision> {
        (**self).read_view(view_id)
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<ViewRevision>> {
        (**self).read_views(belong_to_id)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        (**self).update_view(changeset)
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<ViewRevision> {
        (**self).delete_view(view_id)
    }

    fn move_view(&self, view_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        (**self).move_view(view_id, from, to)
    }

    fn create_trash(&self, trashes: Vec<TrashRevision>) -> FlowyResult<()> {
        (**self).create_trash(trashes)
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<Vec<TrashRevision>> {
        (**self).read_trash(trash_id)
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        (**self).delete_trash(trash_ids)
    }
}
