use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::manager::GridUser;
use crate::services::block_meta_editor::ClientGridBlockMetaEditor;
use crate::services::persistence::block_index::BlockIndexPersistence;
use crate::services::row::{make_block_row_ids, make_rows_from_row_metas, GridBlockSnapshot};

use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_grid_data_model::entities::{
    CellMeta, CellMetaChangeset, CellNotificationData, FieldMeta, GridBlockMeta, GridBlockMetaChangeset,
    GridBlockOrder, RowMeta, RowMetaChangeset, RowOrder,
};
use flowy_revision::disk::SQLiteGridBlockMetaRevisionPersistence;
use flowy_revision::{RevisionManager, RevisionPersistence};
use std::collections::HashMap;
use std::sync::Arc;

pub(crate) struct GridBlockMetaEditorManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    editor_map: DashMap<String, Arc<ClientGridBlockMetaEditor>>,
    persistence: Arc<BlockIndexPersistence>,
}

impl GridBlockMetaEditorManager {
    pub(crate) async fn new(
        grid_id: &str,
        user: &Arc<dyn GridUser>,
        blocks: Vec<GridBlockMeta>,
        persistence: Arc<BlockIndexPersistence>,
    ) -> FlowyResult<Self> {
        let editor_map = make_block_meta_editor_map(user, blocks).await?;
        let user = user.clone();
        let grid_id = grid_id.to_owned();
        let manager = Self {
            grid_id,
            user,
            editor_map,
            persistence,
        };
        Ok(manager)
    }

    // #[tracing::instrument(level = "trace", skip(self))]
    pub(crate) async fn get_editor(&self, block_id: &str) -> FlowyResult<Arc<ClientGridBlockMetaEditor>> {
        debug_assert!(!block_id.is_empty());
        match self.editor_map.get(block_id) {
            None => {
                tracing::error!("The is a fatal error, block is not exist");
                let editor = Arc::new(make_block_meta_editor(&self.user, block_id).await?);
                self.editor_map.insert(block_id.to_owned(), editor.clone());
                Ok(editor)
            }
            Some(editor) => Ok(editor.clone()),
        }
    }

    async fn get_editor_from_row_id(&self, row_id: &str) -> FlowyResult<Arc<ClientGridBlockMetaEditor>> {
        let block_id = self.persistence.get_block_id(row_id)?;
        Ok(self.get_editor(&block_id).await?)
    }

    pub(crate) async fn create_row(
        &self,
        block_id: &str,
        row_meta: RowMeta,
        start_row_id: Option<String>,
    ) -> FlowyResult<i32> {
        let _ = self.persistence.insert_or_update(&row_meta.block_id, &row_meta.id)?;
        let editor = self.get_editor(&row_meta.block_id).await?;
        let row_count = editor.create_row(row_meta, start_row_id).await?;
        self.notify_block_did_update_row(block_id).await?;
        Ok(row_count)
    }

    pub(crate) async fn insert_row(
        &self,
        rows_by_block_id: HashMap<String, Vec<RowMeta>>,
    ) -> FlowyResult<Vec<GridBlockMetaChangeset>> {
        let mut changesets = vec![];
        for (block_id, row_metas) in rows_by_block_id {
            let editor = self.get_editor(&block_id).await?;
            let mut row_count = 0;
            for row in &row_metas {
                let _ = self.persistence.insert_or_update(&row.block_id, &row.id)?;
                row_count = editor.create_row(row.clone(), None).await?;
            }
            changesets.push(GridBlockMetaChangeset::from_row_count(&block_id, row_count));
            let _ = self.notify_block_did_update_row(&block_id).await?;
        }

        Ok(changesets)
    }

    pub(crate) async fn delete_rows(&self, row_orders: Vec<RowOrder>) -> FlowyResult<Vec<GridBlockMetaChangeset>> {
        let mut changesets = vec![];
        for block_row_ids in make_block_row_ids(&row_orders) {
            let editor = self.get_editor(&block_row_ids.block_id).await?;
            let row_count = editor.delete_rows(block_row_ids.row_ids).await?;

            let changeset = GridBlockMetaChangeset::from_row_count(&block_row_ids.block_id, row_count);
            changesets.push(changeset);
        }

        Ok(changesets)
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        let editor = self.get_editor_from_row_id(&changeset.row_id).await?;
        let _ = editor.update_row(changeset.clone()).await?;
        let _ = self.notify_block_did_update_row(&editor.block_id).await?;
        Ok(())
    }

    pub async fn update_cell(&self, changeset: CellMetaChangeset) -> FlowyResult<()> {
        let row_id = changeset.row_id.clone();
        let editor = self.get_editor_from_row_id(&row_id).await?;
        let row_changeset: RowMetaChangeset = changeset.clone().into();
        let _ = editor.update_row(row_changeset).await?;

        let cell_notification_data = CellNotificationData {
            grid_id: changeset.grid_id,
            field_id: changeset.field_id,
            row_id: changeset.row_id,
            content: changeset.data,
        };
        self.notify_did_update_cell(cell_notification_data).await?;
        Ok(())
    }

    pub async fn get_row_meta(&self, row_id: &str) -> FlowyResult<Option<Arc<RowMeta>>> {
        let editor = self.get_editor_from_row_id(row_id).await?;
        let row_ids = vec![row_id.to_owned()];
        let mut row_metas = editor.get_row_metas(Some(row_ids)).await?;
        if row_metas.is_empty() {
            Ok(None)
        } else {
            Ok(row_metas.pop())
        }
    }

    pub(crate) async fn make_block_snapshots(&self, block_ids: Vec<String>) -> FlowyResult<Vec<GridBlockSnapshot>> {
        let mut snapshots = vec![];
        for block_id in block_ids {
            let editor = self.get_editor(&block_id).await?;
            let row_metas = editor.get_row_metas(None).await?;
            snapshots.push(GridBlockSnapshot { block_id, row_metas });
        }
        Ok(snapshots)
    }

    // Optimization: Using the shared memory(Arc, Cow,etc.) to reduce memory usage.
    #[allow(dead_code)]
    pub async fn get_cell_metas(
        &self,
        block_ids: Vec<String>,
        field_id: &str,
        row_ids: Option<Vec<String>>,
    ) -> FlowyResult<Vec<CellMeta>> {
        let mut block_cell_metas = vec![];
        for block_id in block_ids {
            let editor = self.get_editor(&block_id).await?;
            let cell_metas = editor.get_cell_metas(field_id, &row_ids).await?;
            block_cell_metas.extend(cell_metas);
        }
        Ok(block_cell_metas)
    }

    async fn notify_block_did_update_row(&self, block_id: &str) -> FlowyResult<()> {
        let block_order: GridBlockOrder = block_id.into();
        send_dart_notification(&self.grid_id, GridNotification::DidUpdateBlock)
            .payload(block_order)
            .send();
        Ok(())
    }

    async fn notify_did_update_cell(&self, data: CellNotificationData) -> FlowyResult<()> {
        let id = format!("{}:{}", data.row_id, data.field_id);
        send_dart_notification(&id, GridNotification::DidUpdateCell)
            .payload(data)
            .send();
        Ok(())
    }

    #[allow(dead_code)]
    async fn notify_did_update_row(&self, row_id: &str, field_metas: &[FieldMeta]) -> FlowyResult<()> {
        match self.get_row_meta(row_id).await? {
            None => {}
            Some(row_meta) => {
                let row_metas = vec![row_meta];
                if let Some(row) = make_rows_from_row_metas(field_metas, &row_metas).pop() {
                    send_dart_notification(row_id, GridNotification::DidUpdateRow)
                        .payload(row)
                        .send();
                }
            }
        }
        Ok(())

        //
        // let field_meta_map = field_metas
        //     .iter()
        //     .map(|field_meta| (&field_meta.id, field_meta))
        //     .collect::<HashMap<&String, &FieldMeta>>();
        //
        // let mut cells = vec![];
        // changeset
        //     .cell_by_field_id
        //     .into_iter()
        //     .for_each(
        //         |(field_id, cell_meta)| match make_cell_by_field_id(&field_meta_map, field_id, cell_meta) {
        //             None => {}
        //             Some((_, cell)) => cells.push(cell),
        //         },
        //     );
        //
        // if !cells.is_empty() {
        //     send_dart_notification(&changeset.row_id, GridNotification::DidUpdateRow)
        //         .payload(RepeatedCell::from(cells))
        //         .send();
        // }
        // Ok(())
    }
}

async fn make_block_meta_editor_map(
    user: &Arc<dyn GridUser>,
    blocks: Vec<GridBlockMeta>,
) -> FlowyResult<DashMap<String, Arc<ClientGridBlockMetaEditor>>> {
    let editor_map = DashMap::new();
    for block in blocks {
        let editor = make_block_meta_editor(user, &block.block_id).await?;
        editor_map.insert(block.block_id, Arc::new(editor));
    }

    Ok(editor_map)
}

async fn make_block_meta_editor(user: &Arc<dyn GridUser>, block_id: &str) -> FlowyResult<ClientGridBlockMetaEditor> {
    let token = user.token()?;
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;

    let disk_cache = Arc::new(SQLiteGridBlockMetaRevisionPersistence::new(&user_id, pool));
    let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, block_id, disk_cache));
    let rev_manager = RevisionManager::new(&user_id, block_id, rev_persistence);
    ClientGridBlockMetaEditor::new(&user_id, &token, block_id, rev_manager).await
}
