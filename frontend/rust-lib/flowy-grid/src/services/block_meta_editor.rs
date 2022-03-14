use crate::manager::GridUser;
use crate::services::row::make_row_ids_per_block;
use bytes::Bytes;

use dashmap::DashMap;
use flowy_collaboration::client_grid::{GridBlockMetaChange, GridBlockMetaPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    GridBlock, GridBlockChangeset, RepeatedRowOrder, RowMeta, RowMetaChangeset, RowOrder,
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
    user: Arc<dyn GridUser>,
    editor_map: DashMap<String, Arc<ClientGridBlockMetaEditor>>,
    block_id_by_row_id: DashMap<BlockId, RowId>,
}

impl GridBlockMetaEditorManager {
    pub(crate) async fn new(user: &Arc<dyn GridUser>, blocks: Vec<GridBlock>) -> FlowyResult<Self> {
        let editor_map = make_block_meta_editor_map(user, blocks).await?;
        let user = user.clone();
        let block_id_by_row_id = DashMap::new();
        let manager = Self {
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

    pub(crate) async fn create_row(&self, row: RowMeta) -> FlowyResult<i32> {
        self.block_id_by_row_id.insert(row.id.clone(), row.block_id.clone());
        let editor = self.get_editor(&row.block_id).await?;
        editor.create_row(row).await
    }

    pub(crate) async fn insert_row(
        &self,
        rows_by_block_id: HashMap<String, Vec<RowMeta>>,
    ) -> FlowyResult<Vec<GridBlockChangeset>> {
        let mut changesets = vec![];
        for (block_id, rows) in rows_by_block_id {
            let editor = self.get_editor(&block_id).await?;
            let mut row_count = 0;
            for row in rows {
                self.block_id_by_row_id.insert(row.id.clone(), row.block_id.clone());
                row_count = editor.create_row(row).await?;
            }
            changesets.push(GridBlockChangeset::from_row_count(&block_id, row_count));
        }

        Ok(changesets)
    }

    pub(crate) async fn delete_rows(&self, row_ids: Vec<String>) -> FlowyResult<Vec<GridBlockChangeset>> {
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

            let changeset = GridBlockChangeset::from_row_count(&row_ids_per_block.block_id, row_count);
            changesets.push(changeset);
        }

        Ok(changesets)
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        match self.block_id_by_row_id.get(&changeset.row_id) {
            None => {
                let msg = format!(
                    "Update Row failed. Can't find the corresponding block with row_id: {}",
                    changeset.row_id
                );
                Err(FlowyError::internal().context(msg))
            }
            Some(block_id) => {
                let editor = self.get_editor(&block_id).await?;
                editor.update_row(changeset).await
            }
        }
    }

    pub(crate) async fn get_all_rows(&self, grid_blocks: Vec<GridBlock>) -> FlowyResult<Vec<RowMeta>> {
        let mut row_metas = vec![];
        for grid_block in grid_blocks {
            let editor = self.get_editor(&grid_block.id).await?;
            let new_row_metas = editor.get_rows(None).await?;
            new_row_metas.iter().for_each(|row_meta| {
                self.block_id_by_row_id
                    .insert(row_meta.id.clone(), row_meta.block_id.clone());
            });

            row_metas.extend(new_row_metas);
        }
        Ok(row_metas)
    }

    pub(crate) async fn get_rows(&self, row_orders: &RepeatedRowOrder) -> FlowyResult<Vec<RowMeta>> {
        let row_ids_per_blocks = make_row_ids_per_block(row_orders);
        let mut row_metas = vec![];
        for row_ids_per_block in row_ids_per_blocks {
            let editor = self.get_editor(&row_ids_per_block.block_id).await?;
            let new_row_metas = editor.get_rows(Some(row_ids_per_block.row_ids)).await?;
            new_row_metas.iter().for_each(|row_meta| {
                self.block_id_by_row_id
                    .insert(row_meta.id.clone(), row_meta.block_id.clone());
            });
            row_metas.extend(new_row_metas);
        }
        Ok(row_metas)
    }
}

async fn make_block_meta_editor_map(
    user: &Arc<dyn GridUser>,
    blocks: Vec<GridBlock>,
) -> FlowyResult<DashMap<String, Arc<ClientGridBlockMetaEditor>>> {
    let editor_map = DashMap::new();
    for block in blocks {
        let editor = make_block_meta_editor(user, &block.id).await?;
        editor_map.insert(block.id, Arc::new(editor));
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
    meta_pad: Arc<RwLock<GridBlockMetaPad>>,
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
        let meta_pad = Arc::new(RwLock::new(block_meta_pad));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        let block_id = block_id.to_owned();
        Ok(Self {
            user_id,
            block_id,
            meta_pad,
            rev_manager,
        })
    }

    async fn create_row(&self, row: RowMeta) -> FlowyResult<i32> {
        let mut row_count = 0;
        let _ = self
            .modify(|pad| {
                let change = pad.add_row(row)?;
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

    pub async fn get_rows(&self, row_ids: Option<Vec<String>>) -> FlowyResult<Vec<RowMeta>> {
        match row_ids {
            None => Ok(self.meta_pad.read().await.all_rows()),
            Some(row_ids) => {
                let rows = self.meta_pad.read().await.get_rows(row_ids)?;
                Ok(rows)
            }
        }
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockMetaPad) -> FlowyResult<Option<GridBlockMetaChange>>,
    {
        let mut write_guard = self.meta_pad.write().await;
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
        let delta_data = delta.to_bytes();
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
        Ok(delta.to_bytes())
    }
}
