use crate::entities::{
    CreateRowParams, DeleteFilterParams, DeleteGroupParams, GridSettingPB, InsertFilterParams, InsertGroupParams,
    MoveGroupParams, RepeatedGridGroupPB, RowPB,
};
use crate::manager::GridUser;

use crate::services::grid_view_editor::{GridViewEditorDelegate, GridViewRevisionCompress, GridViewRevisionEditor};
use crate::services::persistence::rev_sqlite::SQLiteGridViewRevisionPersistence;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_revision::{
    RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration, SQLiteRevisionSnapshotPersistence,
};
use flowy_task::TaskDispatcher;
use grid_rev_model::{FilterConfigurationRevision, RowChangeset, RowRevision};
use lib_infra::future::AFFuture;
use std::sync::Arc;
use tokio::sync::RwLock;
type ViewId = String;

pub(crate) struct GridViewManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    delegate: Arc<dyn GridViewEditorDelegate>,
    view_editors: DashMap<ViewId, Arc<GridViewRevisionEditor>>,
    scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl GridViewManager {
    pub(crate) async fn new(
        grid_id: String,
        user: Arc<dyn GridUser>,
        delegate: Arc<dyn GridViewEditorDelegate>,
        scheduler: Arc<RwLock<TaskDispatcher>>,
    ) -> FlowyResult<Self> {
        Ok(Self {
            grid_id,
            user,
            delegate,
            view_editors: DashMap::default(),
            scheduler,
        })
    }

    pub(crate) async fn close(&self, view_id: &str) {
        if let Ok(editor) = self.get_default_view_editor().await {
            let _ = editor.close().await;
        }
    }

    pub(crate) async fn duplicate_grid_view(&self) -> FlowyResult<String> {
        let editor = self.get_default_view_editor().await?;
        let view_data = editor.duplicate_view_data().await?;
        Ok(view_data)
    }

    /// When the row was created, we may need to modify the [RowRevision] according to the [CreateRowParams].
    pub(crate) async fn will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.will_create_view_row(row_rev, params).await;
        }
    }

    /// Notify the view that the row was created. For the moment, the view is just sending notifications.
    pub(crate) async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_create_view_row(row_pb, params).await;
        }
    }

    /// Insert/Delete the group's row if the corresponding cell data was changed.  
    pub(crate) async fn did_update_cell(&self, row_id: &str) {
        match self.delegate.get_row_rev(row_id).await {
            None => {
                tracing::warn!("Can not find the row in grid view");
            }
            Some(row_rev) => {
                for view_editor in self.view_editors.iter() {
                    view_editor.did_update_view_cell(&row_rev).await;
                }
            }
        }
    }

    pub(crate) async fn group_by_field(&self, field_id: &str) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _ = view_editor.group_by_view_field(field_id).await?;
        Ok(())
    }

    pub(crate) async fn did_delete_row(&self, row_rev: Arc<RowRevision>) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_delete_view_row(&row_rev).await;
        }
    }

    pub(crate) async fn get_setting(&self) -> FlowyResult<GridSettingPB> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_view_setting().await)
    }

    pub(crate) async fn get_filters(&self) -> FlowyResult<Vec<Arc<FilterConfigurationRevision>>> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_view_filters().await)
    }

    pub(crate) async fn insert_or_update_filter(&self, params: InsertFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.insert_view_filter(params).await
    }

    pub(crate) async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.delete_view_filter(params).await
    }

    pub(crate) async fn load_groups(&self) -> FlowyResult<RepeatedGridGroupPB> {
        let view_editor = self.get_default_view_editor().await?;
        let groups = view_editor.load_view_groups().await?;
        Ok(RepeatedGridGroupPB { items: groups })
    }

    pub(crate) async fn insert_or_update_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.initialize_new_group(params).await
    }

    pub(crate) async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.delete_view_group(params).await
    }

    pub(crate) async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _ = view_editor.move_view_group(params).await?;
        Ok(())
    }

    /// It may generate a RowChangeset when the Row was moved from one group to another.
    /// The return value, [RowChangeset], contains the changes made by the groups.
    ///
    pub(crate) async fn move_group_row(
        &self,
        row_rev: Arc<RowRevision>,
        to_group_id: String,
        to_row_id: Option<String>,
        recv_row_changeset: impl FnOnce(RowChangeset) -> AFFuture<()>,
    ) -> FlowyResult<()> {
        let mut row_changeset = RowChangeset::new(row_rev.id.clone());
        let view_editor = self.get_default_view_editor().await?;
        let group_changesets = view_editor
            .move_view_group_row(&row_rev, &mut row_changeset, &to_group_id, to_row_id.clone())
            .await;

        if !row_changeset.is_empty() {
            recv_row_changeset(row_changeset).await;
        }

        for group_changeset in group_changesets {
            view_editor.notify_did_update_group(group_changeset).await;
        }

        Ok(())
    }

    /// Notifies the view's field type-option data is changed
    /// For the moment, only the groups will be generated after the type-option data changed. A
    /// [FieldRevision] has a property named type_options contains a list of type-option data.
    /// # Arguments
    ///
    /// * `field_id`: the id of the field in current view
    ///
    #[tracing::instrument(level = "trace", skip(self), err)]
    pub(crate) async fn did_update_view_field_type_option(&self, field_id: &str) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        if view_editor.is_grouped().await {
            let _ = view_editor.group_by_view_field(field_id).await?;
        }

        let _ = view_editor.did_update_view_field_type_option(field_id).await?;
        Ok(())
    }

    pub(crate) async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        debug_assert!(!view_id.is_empty());
        match self.view_editors.get(view_id) {
            None => {
                let editor = Arc::new(make_view_editor(&self.user, view_id, self.delegate.clone()).await?);
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
    delegate: Arc<dyn GridViewEditorDelegate>,
) -> FlowyResult<GridViewRevisionEditor> {
    let rev_manager = make_grid_view_rev_manager(user, view_id).await?;
    let user_id = user.user_id()?;
    let token = user.token()?;
    let view_id = view_id.to_owned();

    GridViewRevisionEditor::new(&user_id, &token, view_id, delegate, rev_manager).await
}

pub async fn make_grid_view_rev_manager(
    user: &Arc<dyn GridUser>,
    view_id: &str,
) -> FlowyResult<RevisionManager<Arc<ConnectionPool>>> {
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;

    let disk_cache = SQLiteGridViewRevisionPersistence::new(&user_id, pool.clone());
    let configuration = RevisionPersistenceConfiguration::new(2, false);
    let rev_persistence = RevisionPersistence::new(&user_id, view_id, disk_cache, configuration);
    let rev_compactor = GridViewRevisionCompress();

    let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(view_id, pool);
    Ok(RevisionManager::new(
        &user_id,
        view_id,
        rev_persistence,
        rev_compactor,
        snapshot_persistence,
    ))
}
