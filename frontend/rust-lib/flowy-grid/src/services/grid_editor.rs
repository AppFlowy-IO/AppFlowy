use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::CellIdentifier;
use crate::manager::GridUser;
use crate::services::block_manager::GridBlockManager;
use crate::services::field::{default_type_option_builder_from_type, type_option_builder_from_bytes, FieldBuilder};
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::row::*;
use bytes::Bytes;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::*;
use flowy_grid_data_model::revision::*;
use flowy_revision::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridChangeset, GridRevisionPad, JsonDeserializer};
use flowy_sync::entities::revision::Revision;
use flowy_sync::errors::CollaborateResult;
use flowy_sync::util::make_delta_from_revisions;
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridRevisionEditor {
    grid_id: String,
    user: Arc<dyn GridUser>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    block_manager: Arc<GridBlockManager>,
}

impl Drop for GridRevisionEditor {
    fn drop(&mut self) {
        tracing::trace!("Drop GridMetaEditor");
    }
}

impl GridRevisionEditor {
    pub async fn new(
        grid_id: &str,
        user: Arc<dyn GridUser>,
        mut rev_manager: RevisionManager,
        persistence: Arc<BlockIndexCache>,
    ) -> FlowyResult<Arc<Self>> {
        let token = user.token()?;
        let cloud = Arc::new(GridRevisionCloudService { token });
        let grid_pad = rev_manager.load::<GridPadBuilder>(Some(cloud)).await?;
        let rev_manager = Arc::new(rev_manager);
        let grid_pad = Arc::new(RwLock::new(grid_pad));
        let blocks = grid_pad.read().await.get_block_revs();

        let block_meta_manager = Arc::new(GridBlockManager::new(grid_id, &user, blocks, persistence).await?);
        Ok(Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_pad,
            rev_manager,
            block_manager: block_meta_manager,
        }))
    }

    pub async fn insert_field(&self, params: InsertFieldParams) -> FlowyResult<()> {
        let InsertFieldParams {
            field,
            type_option_data,
            start_field_id,
            grid_id,
        } = params;
        let field_id = field.id.clone();
        if self.contain_field(&field_id).await {
            let _ = self
                .modify(|grid| {
                    let deserializer = TypeOptionJsonDeserializer(field.field_type.clone());
                    let changeset = FieldChangesetParams {
                        field_id: field.id,
                        grid_id,
                        name: Some(field.name),
                        desc: Some(field.desc),
                        field_type: Some(field.field_type),
                        frozen: Some(field.frozen),
                        visibility: Some(field.visibility),
                        width: Some(field.width),
                        type_option_data: Some(type_option_data),
                    };
                    Ok(grid.update_field_rev(changeset, deserializer)?)
                })
                .await?;
            let _ = self.notify_did_update_grid_field(&field_id).await?;
        } else {
            let _ = self
                .modify(|grid| {
                    let builder = type_option_builder_from_bytes(type_option_data, &field.field_type);
                    let field_rev = FieldBuilder::from_field(field, builder).build();

                    Ok(grid.create_field_rev(field_rev, start_field_id)?)
                })
                .await?;
            let _ = self.notify_did_insert_grid_field(&field_id).await?;
        }

        Ok(())
    }

    pub async fn update_field_type_option(
        &self,
        grid_id: &str,
        field_id: &str,
        type_option_data: Vec<u8>,
    ) -> FlowyResult<()> {
        let result = self.get_field_rev(field_id).await;
        if result.is_none() {
            tracing::warn!("Can't find the field with id: {}", field_id);
            return Ok(());
        }
        let field_rev = result.unwrap();
        let _ = self
            .modify(|grid| {
                let deserializer = TypeOptionJsonDeserializer(field_rev.field_type.clone());
                let changeset = FieldChangesetParams {
                    field_id: field_id.to_owned(),
                    grid_id: grid_id.to_owned(),
                    type_option_data: Some(type_option_data),
                    ..Default::default()
                };
                Ok(grid.update_field_rev(changeset, deserializer)?)
            })
            .await?;
        let _ = self.notify_did_update_grid_field(field_id).await?;
        Ok(())
    }

    pub async fn next_field_rev(&self, field_type: &FieldType) -> FlowyResult<FieldRevision> {
        let name = format!("Property {}", self.grid_pad.read().await.fields().len() + 1);
        let field_rev = FieldBuilder::from_field_type(field_type).name(&name).build();
        Ok(field_rev)
    }

    pub async fn create_next_field_rev(&self, field_type: &FieldType) -> FlowyResult<FieldRevision> {
        let field_rev = self.next_field_rev(field_type).await?;
        let _ = self
            .modify(|grid| Ok(grid.create_field_rev(field_rev.clone(), None)?))
            .await?;
        let _ = self.notify_did_insert_grid_field(&field_rev.id).await?;

        Ok(field_rev)
    }

    pub async fn contain_field(&self, field_id: &str) -> bool {
        self.grid_pad.read().await.contain_field(field_id)
    }

    pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
        let field_id = params.field_id.clone();
        let json_deserializer = match self.grid_pad.read().await.get_field_rev(params.field_id.as_str()) {
            None => return Err(ErrorCode::FieldDoesNotExist.into()),
            Some((_, field_rev)) => TypeOptionJsonDeserializer(field_rev.field_type.clone()),
        };

        let _ = self
            .modify(|grid| Ok(grid.update_field_rev(params, json_deserializer)?))
            .await?;

        let _ = self.notify_did_update_grid_field(&field_id).await?;
        Ok(())
    }

    pub async fn replace_field(&self, field_rev: FieldRevision) -> FlowyResult<()> {
        let field_id = field_rev.id.clone();
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.replace_field_rev(field_rev)?))
            .await?;
        let _ = self.notify_did_update_grid_field(&field_id).await?;
        Ok(())
    }

    pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid_pad| Ok(grid_pad.delete_field_rev(field_id)?)).await?;
        let field_order = FieldOrder::from(field_id);
        let notified_changeset = GridFieldChangeset::delete(&self.grid_id, vec![field_order]);
        let _ = self.notify_did_update_grid(notified_changeset).await?;
        Ok(())
    }

    pub async fn switch_to_field_type(&self, field_id: &str, field_type: &FieldType) -> FlowyResult<()> {
        // let block_ids = self
        //     .get_block_metas()
        //     .await?
        //     .into_iter()
        //     .map(|block_meta| block_meta.block_id)
        //     .collect();
        // let cell_revs = self
        //     .block_meta_manager
        //     .get_cell_revs(block_ids, field_id, None)
        //     .await?;

        let type_option_json_builder = |field_type: &FieldType| -> String {
            return default_type_option_builder_from_type(field_type).entry().json_str();
        };

        let _ = self
            .modify(|grid| Ok(grid.switch_to_field(field_id, field_type.clone(), type_option_json_builder)?))
            .await?;

        let _ = self.notify_did_update_grid_field(field_id).await?;

        Ok(())
    }

    pub async fn duplicate_field(&self, field_id: &str) -> FlowyResult<()> {
        let duplicated_field_id = gen_field_id();
        let _ = self
            .modify(|grid| Ok(grid.duplicate_field_rev(field_id, &duplicated_field_id)?))
            .await?;

        let _ = self.notify_did_insert_grid_field(&duplicated_field_id).await?;
        Ok(())
    }

    pub async fn get_field_rev(&self, field_id: &str) -> Option<FieldRevision> {
        let field_rev = self.grid_pad.read().await.get_field_rev(field_id)?.1.clone();
        Some(field_rev)
    }

    pub async fn get_field_revs<T>(&self, field_ids: Option<Vec<T>>) -> FlowyResult<Vec<FieldRevision>>
    where
        T: Into<FieldOrder>,
    {
        if field_ids.is_none() {
            let field_revs = self.grid_pad.read().await.get_field_revs(None)?;
            return Ok(field_revs);
        }

        let to_field_orders = |item: Vec<T>| item.into_iter().map(|data| data.into()).collect();
        let field_orders = field_ids.map_or(vec![], to_field_orders);
        let expected_len = field_orders.len();
        let field_revs = self.grid_pad.read().await.get_field_revs(Some(field_orders))?;
        if expected_len != 0 && field_revs.len() != expected_len {
            tracing::error!(
                "This is a bug. The len of the field_revs should equal to {}",
                expected_len
            );
            debug_assert!(field_revs.len() == expected_len);
        }
        Ok(field_revs)
    }

    pub async fn create_block(&self, grid_block: GridBlockRevision) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.create_block_rev(grid_block)?))
            .await?;
        Ok(())
    }

    pub async fn update_block(&self, changeset: GridBlockRevisionChangeset) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.update_block_rev(changeset)?))
            .await?;
        Ok(())
    }

    pub async fn create_row(&self, start_row_id: Option<String>) -> FlowyResult<RowOrder> {
        let field_revs = self.grid_pad.read().await.get_field_revs(None)?;
        let block_id = self.block_id().await?;

        // insert empty row below the row whose id is upper_row_id
        let row_rev_ctx = CreateRowRevisionBuilder::new(&field_revs).build();
        let row_rev = make_row_rev_from_context(&block_id, row_rev_ctx);
        let row_order = RowOrder::from(&row_rev);

        // insert the row
        let row_count = self.block_manager.create_row(&block_id, row_rev, start_row_id).await?;

        // update block row count
        let changeset = GridBlockRevisionChangeset::from_row_count(&block_id, row_count);
        let _ = self.update_block(changeset).await?;
        Ok(row_order)
    }

    pub async fn insert_rows(&self, contexts: Vec<CreateRowRevisionPayload>) -> FlowyResult<Vec<RowOrder>> {
        let block_id = self.block_id().await?;
        let mut rows_by_block_id: HashMap<String, Vec<RowRevision>> = HashMap::new();
        let mut row_orders = vec![];
        for ctx in contexts {
            let row_rev = make_row_rev_from_context(&block_id, ctx);
            row_orders.push(RowOrder::from(&row_rev));
            rows_by_block_id
                .entry(block_id.clone())
                .or_insert_with(Vec::new)
                .push(row_rev);
        }
        let changesets = self.block_manager.insert_row(rows_by_block_id).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(row_orders)
    }

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        let field_revs = self.get_field_revs::<FieldOrder>(None).await?;
        self.block_manager
            .update_row(changeset, |row_rev| make_row_from_row_rev(&field_revs, row_rev))
            .await
    }

    pub async fn get_rows(&self, block_id: &str) -> FlowyResult<RepeatedRow> {
        let block_ids = vec![block_id.to_owned()];
        let mut grid_block_snapshot = self.grid_block_snapshots(Some(block_ids)).await?;

        // For the moment, we only support one block.
        // We can save the rows into multiple blocks and load them asynchronously in the future.
        debug_assert_eq!(grid_block_snapshot.len(), 1);
        if grid_block_snapshot.len() == 1 {
            let snapshot = grid_block_snapshot.pop().unwrap();
            let field_revs = self.get_field_revs::<FieldOrder>(None).await?;
            let rows = make_rows_from_row_revs(&field_revs, &snapshot.row_revs);
            Ok(rows.into())
        } else {
            Ok(vec![].into())
        }
    }

    pub async fn get_row(&self, row_id: &str) -> FlowyResult<Option<Row>> {
        match self.block_manager.get_row_rev(row_id).await? {
            None => Ok(None),
            Some(row_rev) => {
                let field_revs = self.get_field_revs::<FieldOrder>(None).await?;
                let row_revs = vec![row_rev];
                let mut rows = make_rows_from_row_revs(&field_revs, &row_revs);
                debug_assert!(rows.len() == 1);
                Ok(rows.pop())
            }
        }
    }
    pub async fn delete_row(&self, row_id: &str) -> FlowyResult<()> {
        let _ = self.block_manager.delete_row(row_id).await?;
        Ok(())
    }

    pub async fn duplicate_row(&self, _row_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    pub async fn get_cell(&self, params: &CellIdentifier) -> Option<Cell> {
        let field_rev = self.get_field_rev(&params.field_id).await?;
        let row_rev = self.block_manager.get_row_rev(&params.row_id).await.ok()??;
        make_cell(&params.field_id, &field_rev, &row_rev)
    }

    pub async fn get_cell_rev(&self, row_id: &str, field_id: &str) -> FlowyResult<Option<CellRevision>> {
        let row_rev = self.block_manager.get_row_rev(row_id).await?;
        match row_rev {
            None => Ok(None),
            Some(row_rev) => {
                let cell_rev = row_rev.cells.get(field_id).cloned();
                Ok(cell_rev)
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn update_cell(&self, cell_changeset: CellChangeset) -> FlowyResult<()> {
        if cell_changeset.cell_content_changeset.as_ref().is_none() {
            return Ok(());
        }

        let CellChangeset {
            grid_id,
            row_id,
            field_id,
            mut cell_content_changeset,
        } = cell_changeset;

        match self.grid_pad.read().await.get_field_rev(&field_id) {
            None => {
                let msg = format!("Field not found with id: {}", &field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some((_, field_rev)) => {
                tracing::trace!("field changeset: id:{} / value:{:?}", &field_id, cell_content_changeset);

                let cell_rev = self.get_cell_rev(&row_id, &field_id).await?;
                // Update the changeset.data property with the return value.
                cell_content_changeset = Some(apply_cell_data_changeset(
                    cell_content_changeset.unwrap(),
                    cell_rev,
                    field_rev,
                )?);
                let field_revs = self.get_field_revs::<FieldOrder>(None).await?;
                let cell_changeset = CellChangeset {
                    grid_id,
                    row_id,
                    field_id,
                    cell_content_changeset,
                };
                let _ = self
                    .block_manager
                    .update_cell(cell_changeset, |row_rev| make_row_from_row_rev(&field_revs, row_rev))
                    .await?;
                Ok(())
            }
        }
    }

    pub async fn get_blocks(&self, block_ids: Option<Vec<String>>) -> FlowyResult<RepeatedGridBlock> {
        let block_snapshots = self.grid_block_snapshots(block_ids.clone()).await?;
        make_grid_blocks(block_ids, block_snapshots)
    }

    pub async fn get_block_metas(&self) -> FlowyResult<Vec<GridBlockRevision>> {
        let grid_blocks = self.grid_pad.read().await.get_block_revs();
        Ok(grid_blocks)
    }

    pub async fn delete_rows(&self, row_orders: Vec<RowOrder>) -> FlowyResult<()> {
        let changesets = self.block_manager.delete_rows(row_orders).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(())
    }

    pub async fn get_grid_data(&self) -> FlowyResult<Grid> {
        let pad_read_guard = self.grid_pad.read().await;
        let field_orders = pad_read_guard.get_field_orders();
        let mut block_orders = vec![];
        for block_order in pad_read_guard.get_block_revs() {
            let row_orders = self.block_manager.get_row_orders(&block_order.block_id).await?;
            let block_order = GridBlockOrder {
                block_id: block_order.block_id,
                row_orders,
            };
            block_orders.push(block_order);
        }

        Ok(Grid {
            id: self.grid_id.clone(),
            field_orders,
            block_orders,
        })
    }

    pub async fn get_grid_setting(&self) -> FlowyResult<GridSetting> {
        let read_guard = self.grid_pad.read().await;
        let grid_setting_rev = read_guard.get_grid_setting_rev();
        Ok(grid_setting_rev.into())
    }

    pub async fn get_grid_filter(&self, layout_type: &GridLayoutType) -> FlowyResult<Vec<GridFilter>> {
        let layout_type: GridLayoutRevision = layout_type.clone().into();
        let read_guard = self.grid_pad.read().await;
        match read_guard.get_grid_setting_rev().filter.get(&layout_type) {
            Some(filter_revs) => Ok(filter_revs.iter().map(GridFilter::from).collect::<Vec<GridFilter>>()),
            None => Ok(vec![]),
        }
    }

    pub async fn update_grid_setting(&self, params: GridSettingChangesetParams) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.update_grid_setting_rev(params)?))
            .await?;
        Ok(())
    }

    pub async fn grid_block_snapshots(&self, block_ids: Option<Vec<String>>) -> FlowyResult<Vec<GridBlockSnapshot>> {
        let block_ids = match block_ids {
            None => self
                .grid_pad
                .read()
                .await
                .get_block_revs()
                .into_iter()
                .map(|block_meta| block_meta.block_id)
                .collect::<Vec<String>>(),
            Some(block_ids) => block_ids,
        };
        let snapshots = self.block_manager.make_block_snapshots(block_ids).await?;
        Ok(snapshots)
    }

    pub async fn move_item(&self, params: MoveItemParams) -> FlowyResult<()> {
        match params.ty {
            MoveItemType::MoveField => {
                self.move_field(&params.item_id, params.from_index, params.to_index)
                    .await
            }
            MoveItemType::MoveRow => self.move_row(&params.item_id, params.from_index, params.to_index).await,
        }
    }

    pub async fn move_field(&self, field_id: &str, from: i32, to: i32) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.move_field(field_id, from as usize, to as usize)?))
            .await?;
        if let Some((index, field_rev)) = self.grid_pad.read().await.get_field_rev(field_id) {
            let delete_field_order = FieldOrder::from(field_id);
            let insert_field = IndexField::from_field_rev(field_rev, index);
            let notified_changeset = GridFieldChangeset {
                grid_id: self.grid_id.clone(),
                inserted_fields: vec![insert_field],
                deleted_fields: vec![delete_field_order],
                updated_fields: vec![],
            };

            let _ = self.notify_did_update_grid(notified_changeset).await?;
        }
        Ok(())
    }

    pub async fn move_row(&self, row_id: &str, from: i32, to: i32) -> FlowyResult<()> {
        let _ = self.block_manager.move_row(row_id, from as usize, to as usize).await?;
        Ok(())
    }

    pub async fn delta_bytes(&self) -> Bytes {
        self.grid_pad.read().await.delta_bytes()
    }

    pub async fn duplicate_grid(&self) -> FlowyResult<BuildGridContext> {
        let grid_pad = self.grid_pad.read().await;
        let original_blocks = grid_pad.get_block_revs();
        let (duplicated_fields, duplicated_blocks) = grid_pad.duplicate_grid_meta().await;

        let mut blocks_meta_data = vec![];
        if original_blocks.len() == duplicated_blocks.len() {
            for (index, original_block_meta) in original_blocks.iter().enumerate() {
                let grid_block_meta_editor = self.block_manager.get_editor(&original_block_meta.block_id).await?;
                let duplicated_block_id = &duplicated_blocks[index].block_id;

                tracing::trace!("Duplicate block:{} meta data", duplicated_block_id);
                let duplicated_block_meta_data = grid_block_meta_editor
                    .duplicate_block_meta_data(duplicated_block_id)
                    .await;
                blocks_meta_data.push(duplicated_block_meta_data);
            }
        } else {
            debug_assert_eq!(original_blocks.len(), duplicated_blocks.len());
        }
        drop(grid_pad);

        Ok(BuildGridContext {
            field_revs: duplicated_fields,
            blocks: duplicated_blocks,
            blocks_meta_data,
        })
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridRevisionPad) -> FlowyResult<Option<GridChangeset>>,
    {
        let mut write_guard = self.grid_pad.write().await;
        if let Some(changeset) = f(&mut *write_guard)? {
            let _ = self.apply_change(changeset).await?;
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridChangeset) -> FlowyResult<()> {
        let GridChangeset { delta, md5 } = change;
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

    async fn block_id(&self) -> FlowyResult<String> {
        match self.grid_pad.read().await.get_block_revs().last() {
            None => Err(FlowyError::internal().context("There is no grid block in this grid")),
            Some(grid_block) => Ok(grid_block.block_id.clone()),
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    async fn notify_did_insert_grid_field(&self, field_id: &str) -> FlowyResult<()> {
        if let Some((index, field_rev)) = self.grid_pad.read().await.get_field_rev(field_id) {
            let index_field = IndexField::from_field_rev(field_rev, index);
            let notified_changeset = GridFieldChangeset::insert(&self.grid_id, vec![index_field]);
            let _ = self.notify_did_update_grid(notified_changeset).await?;
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    async fn notify_did_update_grid_field(&self, field_id: &str) -> FlowyResult<()> {
        if let Some((_, field_rev)) = self
            .grid_pad
            .read()
            .await
            .get_field_rev(field_id)
            .map(|(index, field)| (index, field.clone()))
        {
            let updated_field = Field::from(field_rev);
            let notified_changeset = GridFieldChangeset::update(&self.grid_id, vec![updated_field.clone()]);
            let _ = self.notify_did_update_grid(notified_changeset).await?;

            send_dart_notification(field_id, GridNotification::DidUpdateField)
                .payload(updated_field)
                .send();
        }

        Ok(())
    }

    async fn notify_did_update_grid(&self, changeset: GridFieldChangeset) -> FlowyResult<()> {
        send_dart_notification(&self.grid_id, GridNotification::DidUpdateGridField)
            .payload(changeset)
            .send();
        Ok(())
    }
}

#[cfg(feature = "flowy_unit_test")]
impl GridRevisionEditor {
    pub fn rev_manager(&self) -> Arc<RevisionManager> {
        self.rev_manager.clone()
    }
}

pub struct GridPadBuilder();
impl RevisionObjectBuilder for GridPadBuilder {
    type Output = GridRevisionPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridRevisionPad::from_revisions(object_id, revisions)?;
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

struct TypeOptionJsonDeserializer(FieldType);
impl JsonDeserializer for TypeOptionJsonDeserializer {
    fn deserialize(&self, type_option_data: Vec<u8>) -> CollaborateResult<String> {
        // The type_option_data sent from Dart is serialized by protobuf.
        let builder = type_option_builder_from_bytes(type_option_data, &self.0);
        let json = builder.entry().json_str();
        tracing::trace!("Deserialize type option data to: {}", json);
        Ok(json)
    }
}
