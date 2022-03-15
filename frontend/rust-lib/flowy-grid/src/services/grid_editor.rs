use crate::manager::GridUser;
use crate::services::block_meta_editor::GridBlockMetaEditorManager;
use crate::services::kv_persistence::{GridKVPersistence, KVTransaction};
use bytes::Bytes;
use flowy_collaboration::client_grid::{GridChange, GridMetaPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMetaChangeset, Field, FieldChangeset, FieldMeta, Grid, GridBlock, GridBlockChangeset, RepeatedFieldOrder,
    RepeatedRowOrder, Row, RowMeta, RowMetaChangeset,
};
use std::collections::HashMap;

use crate::services::row::{
    make_row_by_row_id, make_rows, row_meta_from_context, CreateRowContext, CreateRowContextBuilder,
};
use flowy_sync::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct ClientGridEditor {
    grid_id: String,
    user: Arc<dyn GridUser>,
    grid_meta_pad: Arc<RwLock<GridMetaPad>>,
    rev_manager: Arc<RevisionManager>,
    block_meta_manager: Arc<GridBlockMetaEditorManager>,
    kv_persistence: Arc<GridKVPersistence>,
}

impl ClientGridEditor {
    pub async fn new(
        grid_id: &str,
        user: Arc<dyn GridUser>,
        mut rev_manager: RevisionManager,
        kv_persistence: Arc<GridKVPersistence>,
    ) -> FlowyResult<Arc<Self>> {
        let token = user.token()?;
        let cloud = Arc::new(GridRevisionCloudService { token });
        let grid_pad = rev_manager.load::<GridPadBuilder>(Some(cloud)).await?;
        let rev_manager = Arc::new(rev_manager);
        let grid_meta_pad = Arc::new(RwLock::new(grid_pad));

        let block_meta_manager =
            Arc::new(GridBlockMetaEditorManager::new(&user, grid_meta_pad.read().await.get_blocks().clone()).await?);

        Ok(Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_meta_pad,
            rev_manager,
            block_meta_manager,
            kv_persistence,
        }))
    }

    pub async fn create_field(&self, field_meta: FieldMeta) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.create_field(field_meta)?)).await?;
        Ok(())
    }

    pub async fn contain_field(&self, field_meta: &FieldMeta) -> bool {
        self.grid_meta_pad.read().await.contain_field(&field_meta.id)
    }

    pub async fn update_field(&self, change: FieldChangeset) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.update_field(change)?)).await?;
        Ok(())
    }

    pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.delete_field(field_id)?)).await?;
        Ok(())
    }

    pub async fn create_block(&self, grid_block: GridBlock) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.create_block(grid_block)?)).await?;
        Ok(())
    }

    pub async fn update_block(&self, changeset: GridBlockChangeset) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.update_block(changeset)?)).await?;
        Ok(())
    }

    pub async fn create_row(&self) -> FlowyResult<()> {
        let field_metas = self.grid_meta_pad.read().await.get_field_metas(None)?;
        let block_id = self.last_block_id().await?;
        let row = row_meta_from_context(&block_id, CreateRowContextBuilder::new(&field_metas).build());
        let row_count = self.block_meta_manager.create_row(row).await?;
        let changeset = GridBlockChangeset::from_row_count(&block_id, row_count);
        let _ = self.update_block(changeset).await?;
        Ok(())
    }

    pub async fn insert_rows(&self, contexts: Vec<CreateRowContext>) -> FlowyResult<()> {
        let block_id = self.last_block_id().await?;
        let mut rows_by_block_id: HashMap<String, Vec<RowMeta>> = HashMap::new();

        for ctx in contexts {
            let row_meta = row_meta_from_context(&block_id, ctx);
            rows_by_block_id
                .entry(block_id.clone())
                .or_insert(Vec::new())
                .push(row_meta);
        }
        let changesets = self.block_meta_manager.insert_row(rows_by_block_id).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(())
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        self.block_meta_manager.update_row(changeset).await
    }

    pub async fn update_cell(&self, changeset: CellMetaChangeset) -> FlowyResult<()> {
        let row_changeset: RowMetaChangeset = changeset.into();
        self.update_row(row_changeset).await
    }

    pub async fn get_rows(&self, row_orders: Option<RepeatedRowOrder>) -> FlowyResult<Vec<Row>> {
        let row_metas = self.get_row_metas(row_orders.as_ref()).await?;
        let field_meta = self.grid_meta_pad.read().await.get_field_metas(None)?;
        match row_orders {
            None => Ok(make_rows(&field_meta, row_metas)),
            Some(row_orders) => {
                let mut row_map: HashMap<String, Row> = make_row_by_row_id(&field_meta, row_metas);
                let rows = row_orders
                    .iter()
                    .flat_map(|row_order| row_map.remove(&row_order.row_id))
                    .collect::<Vec<_>>();
                Ok(rows)
            }
        }
    }

    pub async fn get_row_metas(&self, row_orders: Option<&RepeatedRowOrder>) -> FlowyResult<Vec<Arc<RowMeta>>> {
        match row_orders {
            None => {
                let grid_blocks = self.grid_meta_pad.read().await.get_blocks();
                let row_metas = self.block_meta_manager.get_all_rows(grid_blocks).await?;
                Ok(row_metas)
            }
            Some(row_orders) => {
                let row_metas = self.block_meta_manager.get_rows(row_orders).await?;
                Ok(row_metas)
            }
        }
    }

    pub async fn delete_rows(&self, row_ids: Vec<String>) -> FlowyResult<()> {
        let changesets = self.block_meta_manager.delete_rows(row_ids).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(())
    }

    pub async fn grid_data(&self) -> FlowyResult<Grid> {
        let field_orders = self.grid_meta_pad.read().await.get_field_orders();
        let grid_blocks = self.grid_meta_pad.read().await.get_blocks();
        let row_orders = self.block_meta_manager.get_row_orders(grid_blocks).await?;
        Ok(Grid {
            id: self.grid_id.clone(),
            field_orders,
            row_orders,
        })
    }

    pub async fn get_field_metas(&self, field_orders: Option<RepeatedFieldOrder>) -> FlowyResult<Vec<FieldMeta>> {
        let field_meta = self.grid_meta_pad.read().await.get_field_metas(field_orders)?;
        Ok(field_meta)
    }

    pub async fn get_blocks(&self) -> FlowyResult<Vec<GridBlock>> {
        let grid_blocks = self.grid_meta_pad.read().await.get_blocks();
        Ok(grid_blocks)
    }

    pub async fn delta_bytes(&self) -> Bytes {
        self.grid_meta_pad.read().await.delta_bytes()
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridMetaPad) -> FlowyResult<Option<GridChange>>,
    {
        let mut write_guard = self.grid_meta_pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridChange) -> FlowyResult<()> {
        let GridChange { delta, md5 } = change;
        let user_id = self.user.user_id()?;
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
            .add_local_revision(&revision, Box::new(GridRevisionCompactor()))
            .await?;
        Ok(())
    }

    async fn last_block_id(&self) -> FlowyResult<String> {
        match self.grid_meta_pad.read().await.get_blocks().last() {
            None => Err(FlowyError::internal().context("There is no grid block in this grid")),
            Some(grid_block) => Ok(grid_block.id.clone()),
        }
    }
}

#[cfg(feature = "flowy_unit_test")]
impl ClientGridEditor {
    pub fn rev_manager(&self) -> Arc<RevisionManager> {
        self.rev_manager.clone()
    }
}

pub struct GridPadBuilder();
impl RevisionObjectBuilder for GridPadBuilder {
    type Output = GridMetaPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridMetaPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

struct GridRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridRevisionCompactor();
impl RevisionCompactor for GridRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Ok(delta.to_delta_bytes())
    }
}
