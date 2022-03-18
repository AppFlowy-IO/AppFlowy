use crate::manager::GridUser;
use crate::services::row::{make_cell, make_row_ids_per_block, GridBlockMetaData};
use bytes::Bytes;

use crate::dart_notification::{send_dart_notification, GridNotification};
use dashmap::DashMap;
use flowy_collaboration::client_grid::{GridBlockMetaChange, GridBlockMetaPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    FieldMeta, GridBlockId, GridBlockMeta, GridBlockMetaChangeset, RepeatedCell, RepeatedRowOrder, RowMeta,
    RowMetaChangeset, RowOrder,
};
use flowy_sync::disk::SQLiteGridBlockMetaRevisionPersistence;
use flowy_sync::{
    RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder, RevisionPersistence,
};
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;
type BlockId = String;

pub(crate) struct GridBlockMetaEditorManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    editor_map: DashMap<String, Arc<ClientGridBlockMetaEditor>>,
    block_id_by_row_id: DashMap<BlockId, RowId>,
}

impl GridBlockMetaEditorManager {
    pub(crate) async fn new(grid_id: &str, user: &Arc<dyn GridUser>, blocks: Vec<GridBlockMeta>) -> FlowyResult<Self> {
        let editor_map = make_block_meta_editor_map(user, blocks).await?;
        let user = user.clone();
        let block_id_by_row_id = DashMap::new();
        let grid_id = grid_id.to_owned();
        let manager = Self {
            grid_id,
            user,
            editor_map,
            block_id_by_row_id,
        };
        Ok(manager)
    }

    pub(crate) async fn get_editor(&self, block_id: &str) -> FlowyResult<Arc<ClientGridBlockMetaEditor>> {
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

    pub(crate) async fn create_row(
        &self,
        block_id: &str,
        row_meta: RowMeta,
        start_row_id: Option<String>,
    ) -> FlowyResult<i32> {
        self.block_id_by_row_id
            .insert(row_meta.id.clone(), row_meta.block_id.clone());
        let editor = self.get_editor(&row_meta.block_id).await?;
        let row_count = editor.create_row(row_meta, start_row_id).await?;
        self.notify_did_update_block(block_id).await?;
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
                self.block_id_by_row_id.insert(row.id.clone(), row.block_id.clone());
                row_count = editor.create_row(row.clone(), None).await?;
            }
            changesets.push(GridBlockMetaChangeset::from_row_count(&block_id, row_count));
            let _ = self.notify_did_update_block(&block_id).await?;
        }

        Ok(changesets)
    }

    pub(crate) async fn delete_rows(&self, row_ids: Vec<String>) -> FlowyResult<Vec<GridBlockMetaChangeset>> {
        let row_orders = row_ids
            .into_iter()
            .flat_map(|row_id| {
                self.block_id_by_row_id.get(&row_id).map(|block_id| RowOrder {
                    row_id,
                    block_id: block_id.clone(),
                })
            })
            .collect::<Vec<RowOrder>>();
        let mut changesets = vec![];
        let row_ids_per_blocks = make_row_ids_per_block(&row_orders);
        for row_ids_per_block in row_ids_per_blocks {
            let editor = self.get_editor(&row_ids_per_block.block_id).await?;
            let row_count = editor.delete_rows(row_ids_per_block.row_ids).await?;

            let changeset = GridBlockMetaChangeset::from_row_count(&row_ids_per_block.block_id, row_count);
            changesets.push(changeset);
        }

        Ok(changesets)
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        let editor = self.get_editor_from_row_id(&changeset.row_id).await?;
        let _ = editor.update_row(changeset.clone()).await?;
        let _ = self.notify_did_update_block(&editor.block_id).await?;
        Ok(())
    }

    pub async fn get_row(&self, block_id: &str, row_id: &str) -> FlowyResult<Option<Arc<RowMeta>>> {
        let editor = self.get_editor(block_id).await?;
        let mut row_metas = editor.get_row_metas(Some(vec![row_id.to_owned()])).await?;
        if row_metas.is_empty() {
            Ok(None)
        } else {
            Ok(row_metas.pop())
        }
    }

    pub async fn update_cells(&self, field_metas: &[FieldMeta], changeset: RowMetaChangeset) -> FlowyResult<()> {
        let editor = self.get_editor_from_row_id(&changeset.row_id).await?;
        let _ = editor.update_row(changeset.clone()).await?;
        self.notify_did_update_cells(changeset, field_metas)?;
        Ok(())
    }

    pub(crate) async fn get_block_meta_data_from_blocks(
        &self,
        grid_blocks: Vec<GridBlockMeta>,
    ) -> FlowyResult<Vec<GridBlockMetaData>> {
        let mut snapshots = vec![];
        for grid_block in grid_blocks {
            let editor = self.get_editor(&grid_block.block_id).await?;
            let row_metas = editor.get_row_metas(None).await?;
            row_metas.iter().for_each(|row_meta| {
                self.block_id_by_row_id
                    .insert(row_meta.id.clone(), row_meta.block_id.clone());
            });

            snapshots.push(GridBlockMetaData {
                block_id: grid_block.block_id,
                row_metas,
            });
        }
        Ok(snapshots)
    }

    pub(crate) async fn get_block_meta_data(&self, block_ids: &[String]) -> FlowyResult<Vec<GridBlockMetaData>> {
        let mut snapshots = vec![];
        for block_id in block_ids {
            let editor = self.get_editor(&block_id).await?;
            let row_metas = editor.get_row_metas(None).await?;
            row_metas.iter().for_each(|row_meta| {
                self.block_id_by_row_id
                    .insert(row_meta.id.clone(), row_meta.block_id.clone());
            });
            snapshots.push(GridBlockMetaData {
                block_id: block_id.clone(),
                row_metas,
            });
        }
        Ok(snapshots)
    }

    pub(crate) async fn get_row_orders(&self, grid_block_ids: Vec<String>) -> FlowyResult<Vec<RowOrder>> {
        let mut row_orders = vec![];
        for grid_block_id in grid_block_ids {
            let editor = self.get_editor(&grid_block_id).await?;
            let new_row_order = editor.get_row_orders().await?;
            row_orders.extend(new_row_order);
        }
        Ok(row_orders)
    }

    async fn get_editor_from_row_id(&self, row_id: &str) -> FlowyResult<Arc<ClientGridBlockMetaEditor>> {
        match self.block_id_by_row_id.get(row_id) {
            None => {
                let msg = format!(
                    "Update Row failed. Can't find the corresponding block with row_id: {}",
                    row_id
                );
                Err(FlowyError::internal().context(msg))
            }
            Some(block_id) => {
                let editor = self.get_editor(&block_id).await?;
                Ok(editor)
            }
        }
    }

    async fn notify_did_update_block(&self, block_id: &str) -> FlowyResult<()> {
        let block_id = GridBlockId {
            value: block_id.to_owned(),
        };
        send_dart_notification(&self.grid_id, GridNotification::GridDidUpdateBlock)
            .payload(block_id)
            .send();
        Ok(())
    }

    fn notify_did_update_cells(&self, changeset: RowMetaChangeset, field_metas: &[FieldMeta]) -> FlowyResult<()> {
        let field_meta_map = field_metas
            .iter()
            .map(|field_meta| (&field_meta.id, field_meta))
            .collect::<HashMap<&String, &FieldMeta>>();

        let mut cells = vec![];
        changeset
            .cell_by_field_id
            .into_iter()
            .for_each(
                |(field_id, cell_meta)| match make_cell(&field_meta_map, field_id, cell_meta) {
                    None => {}
                    Some((_, cell)) => cells.push(cell),
                },
            );

        if !cells.is_empty() {
            send_dart_notification(&changeset.row_id, GridNotification::GridDidUpdateCells)
                .payload(RepeatedCell::from(cells))
                .send();
        }
        Ok(())
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

pub struct ClientGridBlockMetaEditor {
    user_id: String,
    pub block_id: String,
    pad: Arc<RwLock<GridBlockMetaPad>>,
    rev_manager: Arc<RevisionManager>,
}

impl ClientGridBlockMetaEditor {
    pub async fn new(
        user_id: &str,
        token: &str,
        block_id: &str,
        mut rev_manager: RevisionManager,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(GridBlockMetaRevisionCloudService {
            token: token.to_owned(),
        });
        let block_meta_pad = rev_manager.load::<GridBlockMetaPadBuilder>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(block_meta_pad));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        let block_id = block_id.to_owned();
        Ok(Self {
            user_id,
            block_id,
            pad,
            rev_manager,
        })
    }

    async fn create_row(&self, row: RowMeta, start_row_id: Option<String>) -> FlowyResult<i32> {
        let mut row_count = 0;
        let _ = self
            .modify(|pad| {
                let change = pad.add_row(row, start_row_id)?;
                row_count = pad.number_of_rows();
                Ok(change)
            })
            .await?;

        Ok(row_count)
    }

    pub async fn delete_rows(&self, ids: Vec<String>) -> FlowyResult<i32> {
        let mut row_count = 0;
        let _ = self
            .modify(|pad| {
                let changeset = pad.delete_rows(&ids)?;
                row_count = pad.number_of_rows();
                Ok(changeset)
            })
            .await?;
        Ok(row_count)
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        let _ = self.modify(|pad| Ok(pad.update_row(changeset)?)).await?;
        Ok(())
    }

    pub async fn get_row_metas(&self, row_ids: Option<Vec<String>>) -> FlowyResult<Vec<Arc<RowMeta>>> {
        let row_metas = self.pad.read().await.get_rows(row_ids)?;
        Ok(row_metas)
    }

    pub async fn get_row_orders(&self) -> FlowyResult<Vec<RowOrder>> {
        let row_orders = self
            .pad
            .read()
            .await
            .get_rows(None)?
            .iter()
            .map(RowOrder::from)
            .collect::<Vec<RowOrder>>();
        Ok(row_orders)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockMetaPad) -> FlowyResult<Option<GridBlockMetaChange>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridBlockMetaChange) -> FlowyResult<()> {
        let GridBlockMetaChange { delta, md5 } = change;
        let user_id = self.user_id.clone();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_delta_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &user_id,
            md5,
        );
        let _ = self
            .rev_manager
            .add_local_revision(&revision, Box::new(GridBlockMetaRevisionCompactor()))
            .await?;
        Ok(())
    }
}

struct GridBlockMetaRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridBlockMetaRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridBlockMetaPadBuilder();
impl RevisionObjectBuilder for GridBlockMetaPadBuilder {
    type Output = GridBlockMetaPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridBlockMetaPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

struct GridBlockMetaRevisionCompactor();
impl RevisionCompactor for GridBlockMetaRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Ok(delta.to_delta_bytes())
    }
}
