use crate::manager::GridUser;
use crate::services::kv_persistence::{GridKVPersistence, KVTransaction};
use crate::services::stringify::stringify_deserialize;

use crate::services::grid_meta_editor::ClientGridBlockMetaEditor;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::client_grid::{GridChange, GridMetaPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    Cell, CellMeta, Field, Grid, RepeatedField, RepeatedFieldOrder, RepeatedRow, RepeatedRowOrder, Row, RowMeta,
};
use flowy_sync::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use lib_infra::future::FutureResult;
use lib_infra::uuid;
use lib_ot::core::{Delta, PlainTextAttributes};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use std::collections::HashMap;
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
        let grid_pad = rev_manager.load::<GridPadBuilder>(cloud).await?;

        let rev_manager = Arc::new(rev_manager);
        let grid_meta_pad = Arc::new(RwLock::new(grid_pad));
        let block_meta_manager = Arc::new(GridBlockMetaEditorManager::new());

        Ok(Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_meta_pad,
            rev_manager,
            block_meta_manager,
            kv_persistence,
        }))
    }

    pub async fn create_field(&mut self, field: Field) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.create_field(field)?)).await?;
        Ok(())
    }

    pub async fn delete_field(&mut self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.delete_field(field_id)?)).await?;
        Ok(())
    }

    pub async fn create_empty_row(&self) -> FlowyResult<()> {
        // let _ = self.modify(|grid| {
        //
        //
        //     grid.blocks
        //
        // }).await?;
        todo!()
    }

    async fn create_row(&self, row: RowMeta) -> FlowyResult<()> {
        todo!()
    }

    pub async fn get_rows(&self, row_orders: RepeatedRowOrder) -> FlowyResult<RepeatedRow> {
        todo!()
    }

    pub async fn delete_rows(&self, ids: Vec<String>) -> FlowyResult<()> {
        todo!()
    }

    pub async fn grid_data(&self) -> Grid {
        todo!()
    }

    pub async fn get_fields(&self, field_orders: RepeatedFieldOrder) -> FlowyResult<RepeatedField> {
        let fields = self.grid_meta_pad.read().await.get_fields(field_orders)?;
        Ok(fields)
    }

    pub async fn delta_str(&self) -> String {
        self.grid_meta_pad.read().await.delta_str()
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
            .add_local_revision(&revision, Box::new(GridRevisionCompactor()))
            .await?;
        Ok(())
    }
}

async fn load_all_fields(
    grid_pad: &GridMetaPad,
    kv_persistence: &Arc<GridKVPersistence>,
) -> FlowyResult<DashMap<String, Field>> {
    let field_ids = grid_pad
        .fields()
        .iter()
        .map(|field| field.id.clone())
        .collect::<Vec<_>>();

    let fields = kv_persistence.batch_get::<Field>(field_ids)?;
    let map = DashMap::new();
    for field in fields {
        map.insert(field.id.clone(), field);
    }
    Ok(map)
}

struct GridPadBuilder();
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
        Ok(delta.to_bytes())
    }
}

struct GridBlockMetaEditorManager {
    editor_map: DashMap<String, Arc<ClientGridBlockMetaEditor>>,
}

impl GridBlockMetaEditorManager {
    fn new() -> Self {
        Self {
            editor_map: DashMap::new(),
        }
    }

    pub async fn get_rows(&self, row_orders: RepeatedRowOrder) -> FlowyResult<RepeatedRow> {
        // let ids = row_orders
        //     .items
        //     .into_iter()
        //     .map(|row_order| row_order.row_id)
        //     .collect::<Vec<_>>();
        // let row_metas: Vec<RowMeta> = self.kv_persistence.batch_get(ids)?;
        //
        // let make_cell = |field_id: String, raw_cell: CellMeta| {
        //     let some_field = self.field_map.get(&field_id);
        //     if some_field.is_none() {
        //         tracing::error!("Can't find the field with {}", field_id);
        //         return None;
        //     }
        //     self.cell_map.insert(raw_cell.id.clone(), raw_cell.clone());
        //
        //     let field = some_field.unwrap();
        //     match stringify_deserialize(raw_cell.data, field.value()) {
        //         Ok(content) => {
        //             let cell = Cell {
        //                 id: raw_cell.id,
        //                 field_id: field_id.clone(),
        //                 content,
        //             };
        //             Some((field_id, cell))
        //         }
        //         Err(_) => None,
        //     }
        // };
        //
        // let rows = row_metas
        //     .into_par_iter()
        //     .map(|row_meta| {
        //         let mut row = Row {
        //             id: row_meta.id.clone(),
        //             cell_by_field_id: Default::default(),
        //             height: row_meta.height,
        //         };
        //         row.cell_by_field_id = row_meta
        //             .cell_by_field_id
        //             .into_par_iter()
        //             .flat_map(|(field_id, raw_cell)| make_cell(field_id, raw_cell))
        //             .collect::<HashMap<String, Cell>>();
        //         row
        //     })
        //     .collect::<Vec<Row>>();
        //
        // Ok(rows.into())
        todo!()
    }
}
