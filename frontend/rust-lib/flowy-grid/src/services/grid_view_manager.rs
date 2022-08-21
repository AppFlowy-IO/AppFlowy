use crate::entities::{
    CreateFilterParams, CreateRowParams, DeleteFilterParams, GridFilterConfiguration, GridSettingChangesetParams,
    GridSettingPB, MoveGroupParams, RepeatedGridGroupPB, RowPB,
};
use crate::manager::GridUser;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::grid_view_editor::GridViewRevisionEditor;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowChangeset, RowRevision};
use flowy_revision::disk::SQLiteGridViewRevisionPersistence;
use flowy_revision::{RevisionCompactor, RevisionManager, RevisionPersistence, SQLiteRevisionSnapshotPersistence};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_text_delta_from_revisions;
use lib_infra::future::AFFuture;
use std::sync::Arc;

type ViewId = String;

pub trait GridViewFieldDelegate: Send + Sync + 'static {
    fn get_field_revs(&self) -> AFFuture<Vec<Arc<FieldRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>>;
}

pub trait GridViewRowDelegate: Send + Sync + 'static {
    fn gv_index_of_row(&self, row_id: &str) -> AFFuture<Option<usize>>;
    fn gv_get_row_rev(&self, row_id: &str) -> AFFuture<Option<Arc<RowRevision>>>;
    fn gv_row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>>;
}

pub(crate) struct GridViewManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
    view_editors: DashMap<ViewId, Arc<GridViewRevisionEditor>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
}

impl GridViewManager {
    pub(crate) async fn new(
        grid_id: String,
        user: Arc<dyn GridUser>,
        field_delegate: Arc<dyn GridViewFieldDelegate>,
        row_delegate: Arc<dyn GridViewRowDelegate>,
        scheduler: Arc<dyn GridServiceTaskScheduler>,
    ) -> FlowyResult<Self> {
        Ok(Self {
            grid_id,
            user,
            scheduler,
            field_delegate,
            row_delegate,
            view_editors: DashMap::default(),
        })
    }

    /// When the row was created, we may need to modify the [RowRevision] according to the [CreateRowParams].
    pub(crate) async fn will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.will_create_row(row_rev, params).await;
        }
    }

    /// Notify the view that the row was created. For the moment, the view is just sending notifications.
    pub(crate) async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_create_row(row_pb, params).await;
        }
    }

    /// Insert/Delete the group's row if the corresponding data was changed.  
    pub(crate) async fn did_update_row(&self, row_id: &str) {
        match self.row_delegate.gv_get_row_rev(row_id).await {
            None => {
                tracing::warn!("Can not find the row in grid view");
            }
            Some(row_rev) => {
                for view_editor in self.view_editors.iter() {
                    view_editor.did_update_row(&row_rev).await;
                }
            }
        }
    }

    pub(crate) async fn did_update_cell(&self, row_id: &str, _field_id: &str) {
        self.did_update_row(row_id).await
    }

    pub(crate) async fn did_delete_row(&self, row_rev: Arc<RowRevision>) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_delete_row(&row_rev).await;
        }
    }

    pub(crate) async fn get_setting(&self) -> FlowyResult<GridSettingPB> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_setting().await)
    }

    pub(crate) async fn get_filters(&self) -> FlowyResult<Vec<GridFilterConfiguration>> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_filters().await)
    }

    pub(crate) async fn update_filter(&self, insert_filter: CreateFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.insert_filter(insert_filter).await
    }

    pub(crate) async fn delete_filter(&self, delete_filter: DeleteFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.delete_filter(delete_filter).await
    }

    pub(crate) async fn load_groups(&self) -> FlowyResult<RepeatedGridGroupPB> {
        let view_editor = self.get_default_view_editor().await?;
        let groups = view_editor.load_groups().await?;
        Ok(RepeatedGridGroupPB { items: groups })
    }

    pub(crate) async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _s = view_editor.move_group(params).await?;
        Ok(())
    }

    /// It may generate a RowChangeset when the Row was moved from one group to another.
    /// The return value, [RowChangeset], contains the changes made by the groups.
    ///
    pub(crate) async fn move_row(&self, row_rev: Arc<RowRevision>, to_row_id: String) -> Option<RowChangeset> {
        let mut row_changeset = RowChangeset::new(row_rev.id.clone());
        for view_editor in self.view_editors.iter() {
            view_editor.did_move_row(&row_rev, &mut row_changeset, &to_row_id).await;
        }

        if row_changeset.has_changed() {
            Some(row_changeset)
        } else {
            None
        }
    }

    pub(crate) async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        debug_assert!(!view_id.is_empty());
        match self.view_editors.get(view_id) {
            None => {
                let editor = Arc::new(
                    make_view_editor(
                        &self.user,
                        view_id,
                        self.field_delegate.clone(),
                        self.row_delegate.clone(),
                        self.scheduler.clone(),
                    )
                    .await?,
                );
                self.view_editors.insert(view_id.to_owned(), editor.clone());
                Ok(editor)
            }
            Some(view_editor) => Ok(view_editor.clone()),
        }
    }

    async fn get_default_view_editor(&self) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        self.get_view_editor(&self.grid_id).await
    }
}

async fn make_view_editor(
    user: &Arc<dyn GridUser>,
    view_id: &str,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
) -> FlowyResult<GridViewRevisionEditor> {
    tracing::trace!("Open view:{} editor", view_id);

    let rev_manager = make_grid_view_rev_manager(user, view_id).await?;
    let user_id = user.user_id()?;
    let token = user.token()?;
    let view_id = view_id.to_owned();
    GridViewRevisionEditor::new(
        &user_id,
        &token,
        view_id,
        field_delegate,
        row_delegate,
        scheduler,
        rev_manager,
    )
    .await
}

pub async fn make_grid_view_rev_manager(user: &Arc<dyn GridUser>, view_id: &str) -> FlowyResult<RevisionManager> {
    tracing::trace!("Open view:{} editor", view_id);
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;

    let disk_cache = SQLiteGridViewRevisionPersistence::new(&user_id, pool.clone());
    let rev_persistence = RevisionPersistence::new(&user_id, view_id, disk_cache);
    let rev_compactor = GridViewRevisionCompactor();

    let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(view_id, pool);
    Ok(RevisionManager::new(
        &user_id,
        view_id,
        rev_persistence,
        rev_compactor,
        snapshot_persistence,
    ))
}

pub struct GridViewRevisionCompactor();
impl RevisionCompactor for GridViewRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_text_delta_from_revisions(revisions)?;
        Ok(delta.json_bytes())
    }
}
