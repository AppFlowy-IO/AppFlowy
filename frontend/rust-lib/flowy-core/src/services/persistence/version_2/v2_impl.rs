use crate::services::persistence::{AppChangeset, FolderPersistenceTransaction, ViewChangeset, WorkspaceChangeset};
use flowy_collaboration::{
    entities::revision::Revision,
    folder::{FolderChange, FolderPad},
};
use flowy_core_data_model::entities::{
    app::App,
    prelude::{RepeatedTrash, Trash, View, Workspace},
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::{RevisionCache, RevisionCloudService, RevisionManager, RevisionObjectBuilder};
use lib_infra::future::FutureResult;
use lib_sqlite::ConnectionPool;
use parking_lot::RwLock;
use std::sync::Arc;

const FOLDER_ID: &str = "flowy_folder";

pub struct FolderEditor {
    user_id: String,
    folder_pad: Arc<RwLock<FolderPad>>,
    rev_manager: Arc<RevisionManager>,
}

impl FolderEditor {
    pub async fn new(user_id: &str, token: &str, pool: Arc<ConnectionPool>) -> FlowyResult<Self> {
        let cache = Arc::new(RevisionCache::new(user_id, FOLDER_ID, pool));
        let mut rev_manager = RevisionManager::new(user_id, FOLDER_ID, cache);
        let cloud = Arc::new(FolderRevisionCloudServiceImpl {
            token: token.to_string(),
        });
        let folder_pad = Arc::new(RwLock::new(rev_manager.load::<FolderPadBuilder>(cloud).await?));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        Ok(Self {
            user_id,
            folder_pad,
            rev_manager,
        })
    }

    fn apply_change(&self, change: FolderChange) -> FlowyResult<()> {
        let FolderChange { delta, md5 } = change;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &self.user_id,
            md5,
        );
        let _ = futures::executor::block_on(async { self.rev_manager.add_local_revision(&revision).await })?;
        Ok(())
    }
}

impl FolderPersistenceTransaction for FolderEditor {
    fn create_workspace(&self, _user_id: &str, workspace: Workspace) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().create_workspace(workspace)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_workspaces(&self, _user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>> {
        let workspaces = self.folder_pad.read().read_workspaces(workspace_id)?;
        Ok(workspaces)
    }

    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder_pad
            .write()
            .update_workspace(&changeset.id, changeset.name, changeset.desc)?
        {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().delete_workspace(workspace_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_app(&self, app: App) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().create_app(app)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> {
        if let Some(change) = self
            .folder_pad
            .write()
            .update_app(&changeset.id, changeset.name, changeset.desc)?
        {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_app(&self, app_id: &str) -> FlowyResult<App> {
        let app = self.folder_pad.read().read_app(app_id)?;
        Ok(app)
    }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>> {
        let workspaces = self.folder_pad.read().read_workspaces(Some(workspace_id.to_owned()))?;
        match workspaces.first() {
            None => {
                Err(FlowyError::record_not_found().context(format!("can't find workspace with id {}", workspace_id)))
            },
            Some(workspace) => Ok(workspace.apps.clone().take_items()),
        }
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<App> {
        let app = self.folder_pad.read().read_app(app_id)?;
        if let Some(change) = self.folder_pad.write().delete_app(app_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(app)
    }

    fn create_view(&self, view: View) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().create_view(view)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_view(&self, view_id: &str) -> FlowyResult<View> {
        let view = self.folder_pad.read().read_view(view_id)?;
        Ok(view)
    }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>> {
        let views = self.folder_pad.read().read_views(belong_to_id)?;
        Ok(views)
    }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().update_view(
            &changeset.id,
            changeset.name,
            changeset.desc,
            changeset.modified_time,
        )? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().delete_view(view_id)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().create_trash(trashes)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash> {
        let trash = self.folder_pad.read().read_trash(trash_id)?;
        Ok(RepeatedTrash { items: trash })
    }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> {
        if let Some(change) = self.folder_pad.write().delete_trash(trash_ids)? {
            let _ = self.apply_change(change)?;
        }
        Ok(())
    }
}

struct FolderPadBuilder();
impl RevisionObjectBuilder for FolderPadBuilder {
    type Output = FolderPad;

    fn build_with_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = FolderPad::from_revisions(revisions)?;
        Ok(pad)
    }
}

struct FolderRevisionCloudServiceImpl {
    #[allow(dead_code)]
    token: String,
    // server: Arc<dyn FolderCouldServiceV2>,
}

impl RevisionCloudService for FolderRevisionCloudServiceImpl {
    #[tracing::instrument(level = "debug", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
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

    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> { (**self).delete_workspace(workspace_id) }

    fn create_app(&self, app: App) -> FlowyResult<()> { (**self).create_app(app) }

    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()> { (**self).update_app(changeset) }

    fn read_app(&self, app_id: &str) -> FlowyResult<App> { (**self).read_app(app_id) }

    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>> {
        (**self).read_workspace_apps(workspace_id)
    }

    fn delete_app(&self, app_id: &str) -> FlowyResult<App> { (**self).delete_app(app_id) }

    fn create_view(&self, view: View) -> FlowyResult<()> { (**self).create_view(view) }

    fn read_view(&self, view_id: &str) -> FlowyResult<View> { (**self).read_view(view_id) }

    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>> { (**self).read_views(belong_to_id) }

    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()> { (**self).update_view(changeset) }

    fn delete_view(&self, view_id: &str) -> FlowyResult<()> { (**self).delete_view(view_id) }

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()> { (**self).create_trash(trashes) }

    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash> { (**self).read_trash(trash_id) }

    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()> { (**self).delete_trash(trash_ids) }
}
