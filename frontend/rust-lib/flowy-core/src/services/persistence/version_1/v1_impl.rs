use crate::services::persistence::{
    version_1::{
        app_sql::{AppChangeset, AppTableSql},
        view_sql::{ViewChangeset, ViewTableSql},
        workspace_sql::{WorkspaceChangeset, WorkspaceTableSql},
    },
    FolderPersistenceTransaction, TrashTableSql,
};
use flowy_core_data_model::entities::{
    app::App,
    trash::{RepeatedTrash, Trash},
    view::View,
    workspace::Workspace,
};
use flowy_error::FlowyResult;
use lib_sqlite::DBConnection;

pub struct V1Transaction<'a>(pub &'a DBConnection);

impl<'a> FolderPersistenceTransaction for V1Transaction<'a> {
    fn create_workspace(&self, user_id: &str, workspace: Workspace) -> FlowyResult<()> {
        let _ = WorkspaceTableSql::create_workspace(user_id, workspace, &*self.0)?;
        Ok(())
    }

    fn read_workspaces(&self, user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>> {
        let tables = WorkspaceTableSql::read_workspaces(user_id, workspace_id, &*self.0)?;
        let workspaces = tables.into_iter().map(Workspace::from).collect::<Vec<_>>();
        Ok(workspaces)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        WorkspaceTableSql::update_workspace(changeset, &*self.0)
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        WorkspaceTableSql::delete_workspace(workspace_id, &*self.0)
    }

    fn create_app(&self, app: App) -> FlowyResult<()> {
        let _ = AppTableSql::create_app(app, &*self.0)?;
        Ok(())
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        let _ = AppTableSql::update_app(changeset, &*self.0)?;
        Ok(())
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<App> {
        let table = AppTableSql::read_app(app_id, &*self.0)?;
        Ok(App::from(table))
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>> {
        let tables = AppTableSql::read_workspace_apps(workspace_id, &*self.0)?;
        let apps = tables.into_iter().map(App::from).collect::<Vec<_>>();
        Ok(apps)
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<App> {
        let table = AppTableSql::delete_app(app_id, &*self.0)?;
        Ok(App::from(table))
    }

    fn create_view(&self, view: View) -> FlowyResult<()> {
        let _ = ViewTableSql::create_view(view, &*self.0)?;
        Ok(())
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<View> {
        let table = ViewTableSql::read_view(view_id, &*self.0)?;
        Ok(View::from(table))
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>> {
        let tables = ViewTableSql::read_views(belong_to_id, &*self.0)?;
        let views = tables.into_iter().map(View::from).collect::<Vec<_>>();
        Ok(views)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        let _ = ViewTableSql::update_view(changeset, &*self.0)?;
        Ok(())
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
        let _ = ViewTableSql::delete_view(view_id, &*self.0)?;
        Ok(())
    }

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()> {
        let _ = TrashTableSql::create_trash(trashes, &*self.0)?;
        Ok(())
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash> {
        match trash_id {
            None => TrashTableSql::read_all(&*self.0),
            Some(trash_id) => {
                let table = TrashTableSql::read(&trash_id, &*self.0)?;
                Ok(RepeatedTrash {
                    items: vec![Trash::from(table)],
                })
            }
        }
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        match trash_ids {
            None => TrashTableSql::delete_all(&*self.0),
            Some(trash_ids) => {
                for trash_id in &trash_ids {
                    let _ = TrashTableSql::delete_trash(trash_id, &*self.0)?;
                }
                Ok(())
            }
        }
    }
}

// https://www.reddit.com/r/rust/comments/droxdg/why_arent_traits_impld_for_boxdyn_trait/
impl<T> FolderPersistenceTransaction for Box<T>
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
