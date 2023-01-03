use crate::entities::{
    AlterFilterParams, AlterSortParams, CreateRowParams, DeleteFilterParams, DeleteGroupParams, DeleteSortParams,
    GridSettingPB, InsertGroupParams, MoveGroupParams, RepeatedGroupPB, RowPB,
};
use crate::manager::GridUser;
use crate::services::block_manager::GridBlockEvent;
use crate::services::cell::AtomicCellDataCache;
use crate::services::filter::FilterType;
use crate::services::persistence::rev_sqlite::{
    SQLiteGridRevisionSnapshotPersistence, SQLiteGridViewRevisionPersistence,
};
use crate::services::view_editor::changed_notifier::*;
use crate::services::view_editor::trait_impl::GridViewRevisionMergeable;
use crate::services::view_editor::{GridViewEditorDelegate, GridViewRevisionEditor};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_revision::{RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration};
use grid_rev_model::{FieldRevision, FilterRevision, RowChangeset, RowRevision, SortRevision};
use lib_infra::future::Fut;
use lib_infra::ref_map::RefCountHashMap;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub struct GridViewManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    delegate: Arc<dyn GridViewEditorDelegate>,
    view_editors: Arc<RwLock<RefCountHashMap<Arc<GridViewRevisionEditor>>>>,
    cell_data_cache: AtomicCellDataCache,
}

impl GridViewManager {
    pub async fn new(
        grid_id: String,
        user: Arc<dyn GridUser>,
        delegate: Arc<dyn GridViewEditorDelegate>,
        cell_data_cache: AtomicCellDataCache,
        block_event_rx: broadcast::Receiver<GridBlockEvent>,
    ) -> FlowyResult<Self> {
        let view_editors = Arc::new(RwLock::new(RefCountHashMap::default()));
        listen_on_grid_block_event(block_event_rx, view_editors.clone());
        Ok(Self {
            grid_id,
            user,
            delegate,
            cell_data_cache,
            view_editors,
        })
    }

    pub async fn close(&self, view_id: &str) {
        self.view_editors.write().await.remove(view_id).await;
    }

    pub async fn subscribe_view_changed(&self, view_id: &str) -> FlowyResult<broadcast::Receiver<GridViewChanged>> {
        Ok(self.get_view_editor(view_id).await?.notifier.subscribe())
    }

    pub async fn get_row_revs(&self, view_id: &str, block_id: &str) -> FlowyResult<Vec<Arc<RowRevision>>> {
        let mut row_revs = self.delegate.get_row_revs(Some(vec![block_id.to_owned()])).await;
        if let Ok(view_editor) = self.get_view_editor(view_id).await {
            view_editor.filter_rows(block_id, &mut row_revs).await;
            view_editor.sort_rows(&mut row_revs).await;
        }

        Ok(row_revs)
    }

    pub async fn duplicate_grid_view(&self) -> FlowyResult<String> {
        let editor = self.get_default_view_editor().await?;
        let view_data = editor.duplicate_view_data().await?;
        Ok(view_data)
    }

    /// When the row was created, we may need to modify the [RowRevision] according to the [CreateRowParams].
    pub async fn will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        for view_editor in self.view_editors.read().await.values() {
            view_editor.will_create_view_row(row_rev, params).await;
        }
    }

    /// Notify the view that the row was created. For the moment, the view is just sending notifications.
    pub async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        for view_editor in self.view_editors.read().await.values() {
            view_editor.did_create_view_row(row_pb, params).await;
        }
    }

    /// Insert/Delete the group's row if the corresponding cell data was changed.  
    pub async fn did_update_cell(&self, row_id: &str) {
        match self.delegate.get_row_rev(row_id).await {
            None => {
                tracing::warn!("Can not find the row in grid view");
            }
            Some((_, row_rev)) => {
                for view_editor in self.view_editors.read().await.values() {
                    view_editor.did_update_view_cell(&row_rev).await;
                }
            }
        }
    }

    pub async fn group_by_field(&self, field_id: &str) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _ = view_editor.group_by_view_field(field_id).await?;
        Ok(())
    }

    pub async fn did_delete_row(&self, row_rev: Arc<RowRevision>) {
        for view_editor in self.view_editors.read().await.values() {
            view_editor.did_delete_view_row(&row_rev).await;
        }
    }

    pub async fn get_setting(&self) -> FlowyResult<GridSettingPB> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_view_setting().await)
    }

    pub async fn get_all_filters(&self) -> FlowyResult<Vec<Arc<FilterRevision>>> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_all_view_filters().await)
    }

    pub async fn get_filters(&self, filter_id: &FilterType) -> FlowyResult<Vec<Arc<FilterRevision>>> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_view_filters(filter_id).await)
    }

    pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_view_editor(&params.view_id).await?;
        view_editor.insert_view_filter(params).await
    }

    pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
        let view_editor = self.get_view_editor(&params.view_id).await?;
        view_editor.delete_view_filter(params).await
    }

    pub async fn get_all_sorts(&self, view_id: &str) -> FlowyResult<Vec<Arc<SortRevision>>> {
        let view_editor = self.get_view_editor(view_id).await?;
        Ok(view_editor.get_all_view_sorts().await)
    }

    pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<SortRevision> {
        let view_editor = self.get_view_editor(&params.view_id).await?;
        view_editor.insert_view_sort(params).await
    }

    pub async fn delete_all_sorts(&self, view_id: &str) -> FlowyResult<()> {
        let view_editor = self.get_view_editor(view_id).await?;
        view_editor.delete_all_view_sorts().await
    }

    pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
        let view_editor = self.get_view_editor(&params.view_id).await?;
        view_editor.delete_view_sort(params).await
    }

    pub async fn load_groups(&self) -> FlowyResult<RepeatedGroupPB> {
        let view_editor = self.get_default_view_editor().await?;
        let groups = view_editor.load_view_groups().await?;
        Ok(RepeatedGroupPB { items: groups })
    }

    pub async fn insert_or_update_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.initialize_new_group(params).await
    }

    pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        view_editor.delete_view_group(params).await
    }

    pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _ = view_editor.move_view_group(params).await?;
        Ok(())
    }

    /// It may generate a RowChangeset when the Row was moved from one group to another.
    /// The return value, [RowChangeset], contains the changes made by the groups.
    ///
    pub async fn move_group_row(
        &self,
        row_rev: Arc<RowRevision>,
        to_group_id: String,
        to_row_id: Option<String>,
        recv_row_changeset: impl FnOnce(RowChangeset) -> Fut<()>,
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
            view_editor.notify_did_update_group_rows(group_changeset).await;
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
    pub async fn did_update_view_field_type_option(
        &self,
        field_id: &str,
        old_field_rev: Option<Arc<FieldRevision>>,
    ) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        if view_editor.group_id().await == field_id {
            let _ = view_editor.group_by_view_field(field_id).await?;
        }

        let _ = view_editor
            .did_update_view_field_type_option(field_id, old_field_rev)
            .await?;
        Ok(())
    }

    pub async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        debug_assert!(!view_id.is_empty());
        if let Some(editor) = self.view_editors.read().await.get(view_id) {
            return Ok(editor);
        }
        tracing::trace!("{:p} create view_editor", self);
        let mut view_editors = self.view_editors.write().await;
        let editor = Arc::new(self.make_view_editor(view_id).await?);
        view_editors.insert(view_id.to_owned(), editor.clone());
        Ok(editor)
    }

    async fn get_default_view_editor(&self) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        self.get_view_editor(&self.grid_id).await
    }

    async fn make_view_editor(&self, view_id: &str) -> FlowyResult<GridViewRevisionEditor> {
        let rev_manager = make_grid_view_rev_manager(&self.user, view_id).await?;
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let view_id = view_id.to_owned();

        GridViewRevisionEditor::new(
            &user_id,
            &token,
            view_id,
            self.delegate.clone(),
            self.cell_data_cache.clone(),
            rev_manager,
        )
        .await
    }
}

fn listen_on_grid_block_event(
    mut block_event_rx: broadcast::Receiver<GridBlockEvent>,
    view_editors: Arc<RwLock<RefCountHashMap<Arc<GridViewRevisionEditor>>>>,
) {
    tokio::spawn(async move {
        loop {
            while let Ok(event) = block_event_rx.recv().await {
                let read_guard = view_editors.read().await;
                let view_editors = read_guard.values();
                let event = if view_editors.len() == 1 {
                    Cow::Owned(event)
                } else {
                    Cow::Borrowed(&event)
                };
                for view_editor in view_editors.iter() {
                    view_editor.handle_block_event(event.clone()).await;
                }
            }
        }
    });
}
pub async fn make_grid_view_rev_manager(
    user: &Arc<dyn GridUser>,
    view_id: &str,
) -> FlowyResult<RevisionManager<Arc<ConnectionPool>>> {
    let user_id = user.user_id()?;

    // Create revision persistence
    let pool = user.db_pool()?;
    let disk_cache = SQLiteGridViewRevisionPersistence::new(&user_id, pool.clone());
    let configuration = RevisionPersistenceConfiguration::new(2, false);
    let rev_persistence = RevisionPersistence::new(&user_id, view_id, disk_cache, configuration);

    // Create snapshot persistence
    let snapshot_object_id = format!("grid_view:{}", view_id);
    let snapshot_persistence = SQLiteGridRevisionSnapshotPersistence::new(&snapshot_object_id, pool);

    let rev_compress = GridViewRevisionMergeable();
    Ok(RevisionManager::new(
        &user_id,
        view_id,
        rev_persistence,
        rev_compress,
        snapshot_persistence,
    ))
}
