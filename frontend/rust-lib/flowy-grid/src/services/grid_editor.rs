use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::CellIdentifierParams;
use crate::entities::*;
use crate::manager::{GridTaskSchedulerRwLock, GridUser};
use crate::services::block_manager::GridBlockManager;
use crate::services::cell::{apply_cell_data_changeset, decode_any_cell_data, CellBytes};
use crate::services::field::{default_type_option_builder_from_type, type_option_builder_from_bytes, FieldBuilder};
use crate::services::filter::{GridFilterChangeset, GridFilterService};
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::row::{
    make_grid_blocks, make_row_from_row_rev, make_rows_from_row_revs, GridBlockSnapshot, RowRevisionBuilder,
};
use crate::services::setting::make_grid_setting;
use bytes::Bytes;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::*;
use flowy_revision::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridChangeset, GridRevisionPad, JsonDeserializer};
use flowy_sync::entities::grid::{FieldChangesetParams, GridSettingChangesetParams};
use flowy_sync::entities::revision::Revision;
use flowy_sync::errors::CollaborateResult;
use flowy_sync::util::make_delta_from_revisions;
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridRevisionEditor {
    pub(crate) grid_id: String,
    user: Arc<dyn GridUser>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    block_manager: Arc<GridBlockManager>,
    #[allow(dead_code)]
    pub(crate) filter_service: Arc<GridFilterService>,
}

impl Drop for GridRevisionEditor {
    fn drop(&mut self) {
        tracing::trace!("Drop GridRevisionEditor");
    }
}

impl GridRevisionEditor {
    pub async fn new(
        grid_id: &str,
        user: Arc<dyn GridUser>,
        mut rev_manager: RevisionManager,
        persistence: Arc<BlockIndexCache>,
        task_scheduler: GridTaskSchedulerRwLock,
    ) -> FlowyResult<Arc<Self>> {
        let token = user.token()?;
        let cloud = Arc::new(GridRevisionCloudService { token });
        let grid_pad = rev_manager.load::<GridPadBuilder>(Some(cloud)).await?;
        let rev_manager = Arc::new(rev_manager);
        let grid_pad = Arc::new(RwLock::new(grid_pad));
        let block_meta_revs = grid_pad.read().await.get_block_meta_revs();
        let block_manager = Arc::new(GridBlockManager::new(grid_id, &user, block_meta_revs, persistence).await?);
        let filter_service =
            Arc::new(GridFilterService::new(grid_pad.clone(), block_manager.clone(), task_scheduler.clone()).await);
        let editor = Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_pad,
            rev_manager,
            block_manager,
            filter_service,
        });

        Ok(editor)
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
                        field_type: Some(field.field_type.into()),
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
                let field_type = field_rev.field_type_rev.into();
                let deserializer = TypeOptionJsonDeserializer(field_type);
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
            Some((_, field_rev)) => TypeOptionJsonDeserializer(field_rev.field_type_rev.into()),
        };

        let _ = self
            .modify(|grid| Ok(grid.update_field_rev(params, json_deserializer)?))
            .await?;

        let _ = self.notify_did_update_grid_field(&field_id).await?;
        Ok(())
    }

    pub async fn replace_field(&self, field_rev: Arc<FieldRevision>) -> FlowyResult<()> {
        let field_id = field_rev.id.clone();
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.replace_field_rev(field_rev)?))
            .await?;
        let _ = self.notify_did_update_grid_field(&field_id).await?;
        Ok(())
    }

    pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid_pad| Ok(grid_pad.delete_field_rev(field_id)?)).await?;
        let field_order = GridFieldIdPB::from(field_id);
        let notified_changeset = GridFieldChangesetPB::delete(&self.grid_id, vec![field_order]);
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

        let type_option_json_builder = |field_type: &FieldTypeRevision| -> String {
            let field_type: FieldType = field_type.into();
            return default_type_option_builder_from_type(&field_type).entry().json_str();
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

    pub async fn get_field_rev(&self, field_id: &str) -> Option<Arc<FieldRevision>> {
        let field_rev = self.grid_pad.read().await.get_field_rev(field_id)?.1.clone();
        Some(field_rev)
    }

    pub async fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> FlowyResult<Vec<Arc<FieldRevision>>> {
        if field_ids.is_none() {
            let field_revs = self.grid_pad.read().await.get_field_revs(None)?;
            return Ok(field_revs);
        }

        let field_ids = field_ids.unwrap_or_default();
        let expected_len = field_ids.len();
        let field_revs = self.grid_pad.read().await.get_field_revs(Some(field_ids))?;
        if expected_len != 0 && field_revs.len() != expected_len {
            tracing::error!(
                "This is a bug. The len of the field_revs should equal to {}",
                expected_len
            );
            debug_assert!(field_revs.len() == expected_len);
        }
        Ok(field_revs)
    }

    pub async fn create_block(&self, block_meta_rev: GridBlockMetaRevision) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.create_block_meta_rev(block_meta_rev)?))
            .await?;
        Ok(())
    }

    pub async fn update_block(&self, changeset: GridBlockMetaRevisionChangeset) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.update_block_rev(changeset)?))
            .await?;
        Ok(())
    }

    pub async fn create_row(&self, start_row_id: Option<String>) -> FlowyResult<GridRowPB> {
        let field_revs = self.grid_pad.read().await.get_field_revs(None)?;
        let block_id = self.block_id().await?;

        // insert empty row below the row whose id is upper_row_id
        let row_rev = RowRevisionBuilder::new(&field_revs).build(&block_id);
        let row_order = GridRowPB::from(&row_rev);

        // insert the row
        let row_count = self.block_manager.create_row(&block_id, row_rev, start_row_id).await?;

        // update block row count
        let changeset = GridBlockMetaRevisionChangeset::from_row_count(&block_id, row_count);
        let _ = self.update_block(changeset).await?;
        Ok(row_order)
    }

    pub async fn insert_rows(&self, row_revs: Vec<RowRevision>) -> FlowyResult<Vec<GridRowPB>> {
        let block_id = self.block_id().await?;
        let mut rows_by_block_id: HashMap<String, Vec<RowRevision>> = HashMap::new();
        let mut row_orders = vec![];
        for row_rev in row_revs {
            row_orders.push(GridRowPB::from(&row_rev));
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
        self.block_manager.update_row(changeset, make_row_from_row_rev).await
    }

    pub async fn get_rows(&self, block_id: &str) -> FlowyResult<RepeatedRowPB> {
        let block_ids = vec![block_id.to_owned()];
        let mut grid_block_snapshot = self.grid_block_snapshots(Some(block_ids)).await?;

        // For the moment, we only support one block.
        // We can save the rows into multiple blocks and load them asynchronously in the future.
        debug_assert_eq!(grid_block_snapshot.len(), 1);
        if grid_block_snapshot.len() == 1 {
            let snapshot = grid_block_snapshot.pop().unwrap();
            let rows = make_rows_from_row_revs(&snapshot.row_revs);
            Ok(rows.into())
        } else {
            Ok(vec![].into())
        }
    }

    pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
        match self.block_manager.get_row_rev(row_id).await? {
            None => Ok(None),
            Some(row_rev) => Ok(Some(row_rev)),
        }
    }

    pub async fn delete_row(&self, row_id: &str) -> FlowyResult<()> {
        let _ = self.block_manager.delete_row(row_id).await?;
        Ok(())
    }

    pub async fn duplicate_row(&self, _row_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    pub async fn get_cell(&self, params: &CellIdentifierParams) -> Option<GridCellPB> {
        let cell_bytes = self.get_cell_bytes(params).await?;
        Some(GridCellPB::new(&params.field_id, cell_bytes.to_vec()))
    }

    pub async fn get_cell_bytes(&self, params: &CellIdentifierParams) -> Option<CellBytes> {
        let field_rev = self.get_field_rev(&params.field_id).await?;
        let row_rev = self.block_manager.get_row_rev(&params.row_id).await.ok()??;

        let cell_rev = row_rev.cells.get(&params.field_id)?.clone();
        Some(decode_any_cell_data(cell_rev.data, &field_rev))
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
    pub async fn update_cell(&self, cell_changeset: CellChangesetPB) -> FlowyResult<()> {
        if cell_changeset.content.as_ref().is_none() {
            return Ok(());
        }

        let CellChangesetPB {
            grid_id,
            row_id,
            field_id,
            mut content,
        } = cell_changeset;

        match self.grid_pad.read().await.get_field_rev(&field_id) {
            None => {
                let msg = format!("Field not found with id: {}", &field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some((_, field_rev)) => {
                tracing::trace!("field changeset: id:{} / value:{:?}", &field_id, content);

                let cell_rev = self.get_cell_rev(&row_id, &field_id).await?;
                // Update the changeset.data property with the return value.
                content = Some(apply_cell_data_changeset(content.unwrap(), cell_rev, field_rev)?);
                let cell_changeset = CellChangesetPB {
                    grid_id,
                    row_id,
                    field_id,
                    content,
                };
                let _ = self
                    .block_manager
                    .update_cell(cell_changeset, make_row_from_row_rev)
                    .await?;
                Ok(())
            }
        }
    }

    pub async fn get_blocks(&self, block_ids: Option<Vec<String>>) -> FlowyResult<RepeatedGridBlockPB> {
        let block_snapshots = self.grid_block_snapshots(block_ids.clone()).await?;
        make_grid_blocks(block_ids, block_snapshots)
    }

    pub async fn get_block_meta_revs(&self) -> FlowyResult<Vec<Arc<GridBlockMetaRevision>>> {
        let block_meta_revs = self.grid_pad.read().await.get_block_meta_revs();
        Ok(block_meta_revs)
    }

    pub async fn delete_rows(&self, row_orders: Vec<GridRowPB>) -> FlowyResult<()> {
        let changesets = self.block_manager.delete_rows(row_orders).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(())
    }

    pub async fn get_grid_data(&self) -> FlowyResult<GridPB> {
        let pad_read_guard = self.grid_pad.read().await;
        let field_orders = pad_read_guard
            .get_field_revs(None)?
            .iter()
            .map(GridFieldIdPB::from)
            .collect();
        let mut block_orders = vec![];
        for block_rev in pad_read_guard.get_block_meta_revs() {
            let row_orders = self.block_manager.get_row_orders(&block_rev.block_id).await?;
            let block_order = GridBlockPB {
                id: block_rev.block_id.clone(),
                rows: row_orders,
            };
            block_orders.push(block_order);
        }

        Ok(GridPB {
            id: self.grid_id.clone(),
            fields: field_orders,
            blocks: block_orders,
        })
    }

    pub async fn get_grid_setting(&self) -> FlowyResult<GridSettingPB> {
        let read_guard = self.grid_pad.read().await;
        let grid_setting_rev = read_guard.get_grid_setting_rev();
        let field_revs = read_guard.get_field_revs(None)?;
        let grid_setting = make_grid_setting(grid_setting_rev, &field_revs);
        Ok(grid_setting)
    }

    pub async fn get_grid_filter(&self, layout_type: &GridLayoutType) -> FlowyResult<Vec<GridFilter>> {
        let read_guard = self.grid_pad.read().await;
        let layout_rev = layout_type.clone().into();
        match read_guard.get_filters(Some(&layout_rev), None) {
            Some(filter_revs) => Ok(filter_revs
                .iter()
                .map(|filter_rev| filter_rev.as_ref().into())
                .collect::<Vec<GridFilter>>()),
            None => Ok(vec![]),
        }
    }

    pub async fn update_grid_setting(&self, params: GridSettingChangesetParams) -> FlowyResult<()> {
        let filter_changeset = GridFilterChangeset::from(&params);
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.update_grid_setting_rev(params)?))
            .await?;

        let filter_service = self.filter_service.clone();
        tokio::spawn(async move {
            filter_service.apply_changeset(filter_changeset).await;
        });
        Ok(())
    }

    pub async fn grid_block_snapshots(&self, block_ids: Option<Vec<String>>) -> FlowyResult<Vec<GridBlockSnapshot>> {
        let block_ids = match block_ids {
            None => self
                .grid_pad
                .read()
                .await
                .get_block_meta_revs()
                .iter()
                .map(|block_rev| block_rev.block_id.clone())
                .collect::<Vec<String>>(),
            Some(block_ids) => block_ids,
        };
        let snapshots = self.block_manager.get_block_snapshots(Some(block_ids)).await?;
        Ok(snapshots)
    }

    pub async fn move_item(&self, params: MoveItemParams) -> FlowyResult<()> {
        match params.ty {
            MoveItemTypePB::MoveField => {
                self.move_field(&params.item_id, params.from_index, params.to_index)
                    .await
            }
            MoveItemTypePB::MoveRow => self.move_row(&params.item_id, params.from_index, params.to_index).await,
        }
    }

    pub async fn move_field(&self, field_id: &str, from: i32, to: i32) -> FlowyResult<()> {
        let _ = self
            .modify(|grid_pad| Ok(grid_pad.move_field(field_id, from as usize, to as usize)?))
            .await?;
        if let Some((index, field_rev)) = self.grid_pad.read().await.get_field_rev(field_id) {
            let delete_field_order = GridFieldIdPB::from(field_id);
            let insert_field = IndexFieldPB::from_field_rev(field_rev, index);
            let notified_changeset = GridFieldChangesetPB {
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
        let original_blocks = grid_pad.get_block_meta_revs();
        let (duplicated_fields, duplicated_blocks) = grid_pad.duplicate_grid_block_meta().await;

        let mut blocks_meta_data = vec![];
        if original_blocks.len() == duplicated_blocks.len() {
            for (index, original_block_meta) in original_blocks.iter().enumerate() {
                let grid_block_meta_editor = self.block_manager.get_editor(&original_block_meta.block_id).await?;
                let duplicated_block_id = &duplicated_blocks[index].block_id;

                tracing::trace!("Duplicate block:{} meta data", duplicated_block_id);
                let duplicated_block_meta_data = grid_block_meta_editor.duplicate_block(duplicated_block_id).await;
                blocks_meta_data.push(duplicated_block_meta_data);
            }
        } else {
            debug_assert_eq!(original_blocks.len(), duplicated_blocks.len());
        }
        drop(grid_pad);

        Ok(BuildGridContext {
            field_revs: duplicated_fields.into_iter().map(Arc::new).collect(),
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
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(())
    }

    async fn block_id(&self) -> FlowyResult<String> {
        match self.grid_pad.read().await.get_block_meta_revs().last() {
            None => Err(FlowyError::internal().context("There is no grid block in this grid")),
            Some(grid_block) => Ok(grid_block.block_id.clone()),
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    async fn notify_did_insert_grid_field(&self, field_id: &str) -> FlowyResult<()> {
        if let Some((index, field_rev)) = self.grid_pad.read().await.get_field_rev(field_id) {
            let index_field = IndexFieldPB::from_field_rev(field_rev, index);
            let notified_changeset = GridFieldChangesetPB::insert(&self.grid_id, vec![index_field]);
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
            let updated_field = GridFieldPB::from(field_rev);
            let notified_changeset = GridFieldChangesetPB::update(&self.grid_id, vec![updated_field.clone()]);
            let _ = self.notify_did_update_grid(notified_changeset).await?;

            send_dart_notification(field_id, GridNotification::DidUpdateField)
                .payload(updated_field)
                .send();
        }

        Ok(())
    }

    async fn notify_did_update_grid(&self, changeset: GridFieldChangesetPB) -> FlowyResult<()> {
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

    fn build_object(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridRevisionPad::from_revisions(revisions)?;
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

pub struct GridRevisionCompactor();
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
