use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{CellChangesetPB, GridBlockChangesetPB, InsertedRowPB, RowPB};
use crate::manager::GridUser;
use crate::services::block_editor::{GridBlockRevisionCompactor, GridBlockRevisionEditor};
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::row::{block_from_row_orders, make_row_from_row_rev, GridBlockSnapshot};
use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    GridBlockMetaRevision, GridBlockMetaRevisionChangeset, RowChangeset, RowRevision,
};
use flowy_revision::disk::SQLiteGridBlockRevisionPersistence;
use flowy_revision::{RevisionManager, RevisionPersistence, SQLiteRevisionSnapshotPersistence};
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

type BlockId = String;
pub(crate) struct GridBlockManager {
    user: Arc<dyn GridUser>,
    persistence: Arc<BlockIndexCache>,
    block_editors: DashMap<BlockId, Arc<GridBlockRevisionEditor>>,
}

impl GridBlockManager {
    pub(crate) async fn new(
        user: &Arc<dyn GridUser>,
        block_meta_revs: Vec<Arc<GridBlockMetaRevision>>,
        persistence: Arc<BlockIndexCache>,
    ) -> FlowyResult<Self> {
        let block_editors = make_block_editors(user, block_meta_revs).await?;
        let user = user.clone();
        let manager = Self {
            user,
            block_editors,
            persistence,
        };
        Ok(manager)
    }

    // #[tracing::instrument(level = "trace", skip(self))]
    pub(crate) async fn get_block_editor(&self, block_id: &str) -> FlowyResult<Arc<GridBlockRevisionEditor>> {
        debug_assert!(!block_id.is_empty());
        match self.block_editors.get(block_id) {
            None => {
                tracing::error!("This is a fatal error, block with id:{} is not exist", block_id);
                let editor = Arc::new(make_block_editor(&self.user, block_id).await?);
                self.block_editors.insert(block_id.to_owned(), editor.clone());
                Ok(editor)
            }
            Some(editor) => Ok(editor.clone()),
        }
    }

    pub(crate) async fn get_editor_from_row_id(&self, row_id: &str) -> FlowyResult<Arc<GridBlockRevisionEditor>> {
        let block_id = self.persistence.get_block_id(row_id)?;
        Ok(self.get_block_editor(&block_id).await?)
    }

    pub(crate) async fn create_row(&self, row_rev: RowRevision, start_row_id: Option<String>) -> FlowyResult<i32> {
        let block_id = row_rev.block_id.clone();
        let _ = self.persistence.insert(&row_rev.block_id, &row_rev.id)?;
        let editor = self.get_block_editor(&row_rev.block_id).await?;

        let mut index_row_order = InsertedRowPB::from(&row_rev);
        let (row_count, row_index) = editor.create_row(row_rev, start_row_id).await?;
        index_row_order.index = row_index;
        let changeset = GridBlockChangesetPB::insert(block_id.clone(), vec![index_row_order]);
        let _ = self.notify_did_update_block(&block_id, changeset).await?;
        Ok(row_count)
    }

    pub(crate) async fn insert_row(
        &self,
        rows_by_block_id: HashMap<String, Vec<RowRevision>>,
    ) -> FlowyResult<Vec<GridBlockMetaRevisionChangeset>> {
        let mut changesets = vec![];
        for (block_id, row_revs) in rows_by_block_id {
            let mut inserted_row_orders = vec![];
            let editor = self.get_block_editor(&block_id).await?;
            let mut row_count = 0;
            for row in row_revs {
                let _ = self.persistence.insert(&row.block_id, &row.id)?;
                let mut row_order = InsertedRowPB::from(&row);
                let (count, index) = editor.create_row(row, None).await?;
                row_count = count;
                row_order.index = index;
                inserted_row_orders.push(row_order);
            }
            changesets.push(GridBlockMetaRevisionChangeset::from_row_count(
                block_id.clone(),
                row_count,
            ));

            let _ = self
                .notify_did_update_block(
                    &block_id,
                    GridBlockChangesetPB::insert(block_id.clone(), inserted_row_orders),
                )
                .await?;
        }

        Ok(changesets)
    }

    pub async fn update_row(&self, changeset: RowChangeset) -> FlowyResult<()> {
        let editor = self.get_editor_from_row_id(&changeset.row_id).await?;
        let _ = editor.update_row(changeset.clone()).await?;
        match editor.get_row_rev(&changeset.row_id).await? {
            None => tracing::error!("Internal error: can't find the row with id: {}", changeset.row_id),
            Some(row_rev) => {
                let row_pb = make_row_from_row_rev(row_rev.clone());
                let block_order_changeset = GridBlockChangesetPB::update(&editor.block_id, vec![row_pb]);
                let _ = self
                    .notify_did_update_block(&editor.block_id, block_order_changeset)
                    .await?;
            }
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn delete_row(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
        let row_id = row_id.to_owned();
        let block_id = self.persistence.get_block_id(&row_id)?;
        let editor = self.get_block_editor(&block_id).await?;
        match editor.get_row_rev(&row_id).await? {
            None => Ok(None),
            Some(row_rev) => {
                let _ = editor.delete_rows(vec![Cow::Borrowed(&row_id)]).await?;
                let _ = self
                    .notify_did_update_block(
                        &block_id,
                        GridBlockChangesetPB::delete(&block_id, vec![row_rev.id.clone()]),
                    )
                    .await?;
                Ok(Some(row_rev))
            }
        }
    }

    pub(crate) async fn delete_rows(&self, row_orders: Vec<RowPB>) -> FlowyResult<Vec<GridBlockMetaRevisionChangeset>> {
        let mut changesets = vec![];
        for grid_block in block_from_row_orders(row_orders) {
            let editor = self.get_block_editor(&grid_block.id).await?;
            let row_ids = grid_block
                .rows
                .into_iter()
                .map(|row_info| Cow::Owned(row_info.row_id().to_owned()))
                .collect::<Vec<Cow<String>>>();
            let row_count = editor.delete_rows(row_ids).await?;
            let changeset = GridBlockMetaRevisionChangeset::from_row_count(grid_block.id.clone(), row_count);
            changesets.push(changeset);
        }

        Ok(changesets)
    }
    // This function will be moved to GridViewRevisionEditor
    pub(crate) async fn move_row(&self, row_rev: Arc<RowRevision>, from: usize, to: usize) -> FlowyResult<()> {
        let editor = self.get_editor_from_row_id(&row_rev.id).await?;
        let _ = editor.move_row(&row_rev.id, from, to).await?;

        let delete_row_id = row_rev.id.clone();
        let insert_row = InsertedRowPB {
            index: Some(to as i32),
            row: make_row_from_row_rev(row_rev),
        };

        let notified_changeset = GridBlockChangesetPB {
            block_id: editor.block_id.clone(),
            inserted_rows: vec![insert_row],
            deleted_rows: vec![delete_row_id],
            ..Default::default()
        };

        let _ = self
            .notify_did_update_block(&editor.block_id, notified_changeset)
            .await?;

        Ok(())
    }

    // This function will be moved to GridViewRevisionEditor.
    pub async fn index_of_row(&self, row_id: &str) -> Option<usize> {
        match self.get_editor_from_row_id(row_id).await {
            Ok(editor) => editor.index_of_row(row_id).await,
            Err(_) => None,
        }
    }

    pub async fn update_cell(&self, changeset: CellChangesetPB) -> FlowyResult<()> {
        let row_changeset: RowChangeset = changeset.clone().into();
        let _ = self.update_row(row_changeset).await?;
        self.notify_did_update_cell(changeset).await?;
        Ok(())
    }

    pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
        let editor = self.get_editor_from_row_id(row_id).await?;
        let row_ids = vec![Cow::Borrowed(row_id)];
        let mut row_revs = editor.get_row_revs(Some(row_ids)).await?;
        if row_revs.is_empty() {
            Ok(None)
        } else {
            Ok(row_revs.pop())
        }
    }

    pub async fn get_row_orders(&self, block_id: &str) -> FlowyResult<Vec<RowPB>> {
        let editor = self.get_block_editor(block_id).await?;
        editor.get_row_infos::<&str>(None).await
    }

    pub(crate) async fn get_block_snapshots(
        &self,
        block_ids: Option<Vec<String>>,
    ) -> FlowyResult<Vec<GridBlockSnapshot>> {
        let mut snapshots = vec![];
        match block_ids {
            None => {
                for iter in self.block_editors.iter() {
                    let editor = iter.value();
                    let block_id = editor.block_id.clone();
                    let row_revs = editor.get_row_revs::<&str>(None).await?;
                    snapshots.push(GridBlockSnapshot { block_id, row_revs });
                }
            }
            Some(block_ids) => {
                for block_id in block_ids {
                    let editor = self.get_block_editor(&block_id).await?;
                    let row_revs = editor.get_row_revs::<&str>(None).await?;
                    snapshots.push(GridBlockSnapshot { block_id, row_revs });
                }
            }
        }
        Ok(snapshots)
    }

    async fn notify_did_update_block(&self, block_id: &str, changeset: GridBlockChangesetPB) -> FlowyResult<()> {
        send_dart_notification(block_id, GridNotification::DidUpdateGridBlock)
            .payload(changeset)
            .send();
        Ok(())
    }

    async fn notify_did_update_cell(&self, changeset: CellChangesetPB) -> FlowyResult<()> {
        let id = format!("{}:{}", changeset.row_id, changeset.field_id);
        send_dart_notification(&id, GridNotification::DidUpdateCell).send();
        Ok(())
    }
}

/// Initialize each block editor
async fn make_block_editors(
    user: &Arc<dyn GridUser>,
    block_meta_revs: Vec<Arc<GridBlockMetaRevision>>,
) -> FlowyResult<DashMap<String, Arc<GridBlockRevisionEditor>>> {
    let editor_map = DashMap::new();
    for block_meta_rev in block_meta_revs {
        let editor = make_block_editor(user, &block_meta_rev.block_id).await?;
        editor_map.insert(block_meta_rev.block_id.clone(), Arc::new(editor));
    }

    Ok(editor_map)
}

async fn make_block_editor(user: &Arc<dyn GridUser>, block_id: &str) -> FlowyResult<GridBlockRevisionEditor> {
    tracing::trace!("Open block:{} editor", block_id);
    let token = user.token()?;
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;

    let disk_cache = SQLiteGridBlockRevisionPersistence::new(&user_id, pool.clone());
    let rev_persistence = RevisionPersistence::new(&user_id, block_id, disk_cache);
    let rev_compactor = GridBlockRevisionCompactor();
    let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(block_id, pool);
    let rev_manager = RevisionManager::new(&user_id, block_id, rev_persistence, rev_compactor, snapshot_persistence);
    GridBlockRevisionEditor::new(&user_id, &token, block_id, rev_manager).await
}
