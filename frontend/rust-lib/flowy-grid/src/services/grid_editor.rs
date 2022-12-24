use crate::dart_notification::{send_dart_notification, GridDartNotification};
use crate::entities::CellPathParams;
use crate::entities::*;
use crate::manager::GridUser;
use crate::services::block_manager::GridBlockManager;
use crate::services::cell::{
    apply_cell_data_changeset, decode_type_cell_data, stringify_cell_data, AnyTypeCache, AtomicCellDataCache,
    CellProtobufBlob, TypeCellData,
};
use crate::services::field::{
    default_type_option_builder_from_type, transform_type_option, type_option_builder_from_bytes, FieldBuilder,
};

use crate::services::filter::FilterType;
use crate::services::grid_editor_trait_impl::GridViewEditorDelegateImpl;
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::row::{GridBlockRow, GridBlockRowRevision, RowRevisionBuilder};
use crate::services::view_editor::{GridViewChanged, GridViewManager};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer,
};
use flowy_sync::client_grid::{GridRevisionChangeset, GridRevisionPad, JsonDeserializer};
use flowy_sync::errors::{CollaborateError, CollaborateResult};
use flowy_sync::util::make_operations_from_revisions;
use flowy_task::TaskDispatcher;
use grid_rev_model::*;
use lib_infra::future::{to_fut, FutureResult};
use lib_ot::core::EmptyAttributes;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub struct GridRevisionEditor {
    pub grid_id: String,
    #[allow(dead_code)]
    user: Arc<dyn GridUser>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    view_manager: Arc<GridViewManager>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    block_manager: Arc<GridBlockManager>,
    cell_data_cache: AtomicCellDataCache,
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
        mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
        persistence: Arc<BlockIndexCache>,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
    ) -> FlowyResult<Arc<Self>> {
        let token = user.token()?;
        let cloud = Arc::new(GridRevisionCloudService { token });
        let grid_pad = rev_manager.initialize::<GridRevisionSerde>(Some(cloud)).await?;
        let rev_manager = Arc::new(rev_manager);
        let grid_pad = Arc::new(RwLock::new(grid_pad));
        let cell_data_cache = AnyTypeCache::<u64>::new();

        // Block manager
        let (block_event_tx, block_event_rx) = broadcast::channel(100);
        let block_meta_revs = grid_pad.read().await.get_block_meta_revs();
        let block_manager = Arc::new(GridBlockManager::new(&user, block_meta_revs, persistence, block_event_tx).await?);
        let delegate = Arc::new(GridViewEditorDelegateImpl {
            pad: grid_pad.clone(),
            block_manager: block_manager.clone(),
            task_scheduler,
        });

        // View manager
        let view_manager = Arc::new(
            GridViewManager::new(
                grid_id.to_owned(),
                user.clone(),
                delegate,
                cell_data_cache.clone(),
                block_event_rx,
            )
            .await?,
        );

        let editor = Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_pad,
            rev_manager,
            block_manager,
            view_manager,
            cell_data_cache,
        });

        Ok(editor)
    }

    #[tracing::instrument(name = "close grid editor", level = "trace", skip_all)]
    pub async fn close(&self) {
        self.block_manager.close().await;
        self.rev_manager.generate_snapshot().await;
        self.rev_manager.close().await;
        self.view_manager.close(&self.grid_id).await;
    }

    /// Save the type-option data to disk and send a `GridDartNotification::DidUpdateField` notification
    /// to dart side.
    ///
    /// It will do nothing if the passed-in type_option_data is empty
    /// # Arguments
    ///
    /// * `grid_id`: the id of the grid
    /// * `field_id`: the id of the field
    /// * `type_option_data`: the updated type-option data. The `type-option` data might be empty
    /// if there is no type-option config for that field. For example, the `RichTextTypeOptionPB`.
    ///  
    pub async fn update_field_type_option(
        &self,
        _grid_id: &str,
        field_id: &str,
        type_option_data: Vec<u8>,
        old_field_rev: Option<Arc<FieldRevision>>,
    ) -> FlowyResult<()> {
        let result = self.get_field_rev(field_id).await;
        if result.is_none() {
            tracing::warn!("Can't find the field with id: {}", field_id);
            return Ok(());
        }
        let field_rev = result.unwrap();
        let _ = self
            .modify(|grid| {
                let changeset = grid.modify_field(field_id, |field| {
                    let deserializer = TypeOptionJsonDeserializer(field_rev.ty.into());
                    match deserializer.deserialize(type_option_data) {
                        Ok(json_str) => {
                            let field_type = field.ty;
                            field.insert_type_option_str(&field_type, json_str);
                        }
                        Err(err) => {
                            tracing::error!("Deserialize data to type option json failed: {}", err);
                        }
                    }
                    Ok(Some(()))
                })?;
                Ok(changeset)
            })
            .await?;

        let _ = self
            .view_manager
            .did_update_view_field_type_option(field_id, old_field_rev)
            .await?;
        let _ = self.notify_did_update_grid_field(field_id).await?;
        Ok(())
    }

    pub async fn next_field_rev(&self, field_type: &FieldType) -> FlowyResult<FieldRevision> {
        let name = format!("Property {}", self.grid_pad.read().await.get_fields().len() + 1);
        let field_rev = FieldBuilder::from_field_type(field_type).name(&name).build();
        Ok(field_rev)
    }

    pub async fn create_new_field_rev(&self, field_rev: FieldRevision) -> FlowyResult<()> {
        let field_id = field_rev.id.clone();
        let _ = self.modify(|grid| Ok(grid.create_field_rev(field_rev, None)?)).await?;
        let _ = self.notify_did_insert_grid_field(&field_id).await?;

        Ok(())
    }

    pub async fn create_new_field_rev_with_type_option(
        &self,
        field_type: &FieldType,
        type_option_data: Option<Vec<u8>>,
    ) -> FlowyResult<FieldRevision> {
        let mut field_rev = self.next_field_rev(field_type).await?;
        if let Some(type_option_data) = type_option_data {
            let type_option_builder = type_option_builder_from_bytes(type_option_data, field_type);
            field_rev.insert_type_option(type_option_builder.serializer());
        }
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
        let _ = self
            .modify(|grid| {
                let changeset = grid.modify_field(&params.field_id, |field| {
                    if let Some(name) = params.name {
                        field.name = name;
                    }
                    if let Some(desc) = params.desc {
                        field.desc = desc;
                    }
                    if let Some(field_type) = params.field_type {
                        field.ty = field_type;
                    }
                    if let Some(frozen) = params.frozen {
                        field.frozen = frozen;
                    }
                    if let Some(visibility) = params.visibility {
                        field.visibility = visibility;
                    }
                    if let Some(width) = params.width {
                        field.width = width;
                    }
                    Ok(Some(()))
                })?;
                Ok(changeset)
            })
            .await?;
        let _ = self.notify_did_update_grid_field(&field_id).await?;
        Ok(())
    }

    pub async fn modify_field_rev<F>(&self, field_id: &str, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut FieldRevision) -> FlowyResult<Option<()>>,
    {
        let mut is_changed = false;
        let old_field_rev = self.get_field_rev(field_id).await;
        let _ = self
            .modify(|grid| {
                let changeset = grid.modify_field(field_id, |field_rev| {
                    f(field_rev).map_err(|e| CollaborateError::internal().context(e))
                })?;
                is_changed = changeset.is_some();
                Ok(changeset)
            })
            .await?;

        if is_changed {
            match self
                .view_manager
                .did_update_view_field_type_option(field_id, old_field_rev)
                .await
            {
                Ok(_) => {}
                Err(e) => tracing::error!("View manager update field failed: {:?}", e),
            }
            let _ = self.notify_did_update_grid_field(field_id).await?;
        }
        Ok(())
    }

    pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid_pad| Ok(grid_pad.delete_field_rev(field_id)?)).await?;
        let field_order = FieldIdPB::from(field_id);
        let notified_changeset = GridFieldChangesetPB::delete(&self.grid_id, vec![field_order]);
        let _ = self.notify_did_update_grid(notified_changeset).await?;
        Ok(())
    }

    pub async fn group_by_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.view_manager.group_by_field(field_id).await?;
        Ok(())
    }

    /// Switch the field with id to a new field type.  
    ///
    /// If the field type is not exist before, the default type-option data will be created.
    /// Each field type has its corresponding data, aka, the type-option data. Check out [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid#fieldtype)
    /// for more information
    ///
    /// # Arguments
    ///
    /// * `field_id`: the id of the field
    /// * `new_field_type`: the new field type of the field
    ///
    pub async fn switch_to_field_type(&self, field_id: &str, new_field_type: &FieldType) -> FlowyResult<()> {
        //
        let make_default_type_option = || -> String {
            return default_type_option_builder_from_type(new_field_type)
                .serializer()
                .json_str();
        };

        let type_option_transform =
            |old_field_type: FieldTypeRevision, old_type_option: Option<String>, new_type_option: String| {
                let old_field_type: FieldType = old_field_type.into();
                transform_type_option(&new_type_option, new_field_type, old_type_option, old_field_type)
            };

        let _ = self
            .modify(|grid| {
                Ok(grid.switch_to_field(
                    field_id,
                    new_field_type.clone(),
                    make_default_type_option,
                    type_option_transform,
                )?)
            })
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

    pub async fn create_row(&self, params: CreateRowParams) -> FlowyResult<RowPB> {
        let mut row_rev = self.create_row_rev().await?;

        self.view_manager.will_create_row(&mut row_rev, &params).await;

        let row_pb = self.create_row_pb(row_rev, params.start_row_id.clone()).await?;

        self.view_manager.did_create_row(&row_pb, &params).await;
        Ok(row_pb)
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let _ = self.view_manager.move_group(params).await?;
        Ok(())
    }

    pub async fn insert_rows(&self, row_revs: Vec<RowRevision>) -> FlowyResult<Vec<RowPB>> {
        let block_id = self.block_id().await?;
        let mut rows_by_block_id: HashMap<String, Vec<RowRevision>> = HashMap::new();
        let mut row_orders = vec![];
        for row_rev in row_revs {
            row_orders.push(RowPB::from(&row_rev));
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

    pub async fn update_row(&self, changeset: RowChangeset) -> FlowyResult<()> {
        let row_id = changeset.row_id.clone();
        let _ = self.block_manager.update_row(changeset).await?;
        self.view_manager.did_update_cell(&row_id).await;
        Ok(())
    }

    /// Returns all the rows in this block.
    pub async fn get_row_pbs(&self, view_id: &str, block_id: &str) -> FlowyResult<Vec<RowPB>> {
        let rows = self.view_manager.get_row_revs(view_id, block_id).await?;
        let rows = self
            .view_manager
            .filter_rows(view_id, block_id, rows)
            .await?
            .into_iter()
            .map(|row_rev| RowPB::from(&row_rev))
            .collect();
        Ok(rows)
    }

    pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
        match self.block_manager.get_row_rev(row_id).await? {
            None => Ok(None),
            Some((_, row_rev)) => Ok(Some(row_rev)),
        }
    }

    pub async fn delete_row(&self, row_id: &str) -> FlowyResult<()> {
        let row_rev = self.block_manager.delete_row(row_id).await?;
        tracing::trace!("Did delete row:{:?}", row_rev);
        if let Some(row_rev) = row_rev {
            self.view_manager.did_delete_row(row_rev).await;
        }
        Ok(())
    }

    pub async fn subscribe_view_changed(&self, view_id: &str) -> FlowyResult<broadcast::Receiver<GridViewChanged>> {
        self.view_manager.subscribe_view_changed(view_id).await
    }

    pub async fn duplicate_row(&self, _row_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    pub async fn get_cell(&self, params: &CellPathParams) -> Option<CellPB> {
        let (field_type, cell_bytes) = self.decode_cell_data_from(params).await?;
        Some(CellPB::new(&params.field_id, field_type, cell_bytes.to_vec()))
    }

    pub async fn get_cell_display_str(&self, params: &CellPathParams) -> String {
        let display_str = || async {
            let field_rev = self.get_field_rev(&params.field_id).await?;
            let field_type: FieldType = field_rev.ty.into();
            let cell_rev = self.get_cell_rev(&params.row_id, &params.field_id).await.ok()??;
            let type_cell_data: TypeCellData = cell_rev.try_into().ok()?;
            Some(stringify_cell_data(
                type_cell_data.cell_str,
                &field_type,
                &field_type,
                &field_rev,
            ))
        };

        display_str().await.unwrap_or("".to_string())
    }

    pub async fn get_cell_bytes(&self, params: &CellPathParams) -> Option<CellProtobufBlob> {
        let (_, cell_data) = self.decode_cell_data_from(params).await?;
        Some(cell_data)
    }

    async fn decode_cell_data_from(&self, params: &CellPathParams) -> Option<(FieldType, CellProtobufBlob)> {
        let field_rev = self.get_field_rev(&params.field_id).await?;
        let (_, row_rev) = self.block_manager.get_row_rev(&params.row_id).await.ok()??;
        let cell_rev = row_rev.cells.get(&params.field_id)?.clone();
        Some(decode_type_cell_data(
            cell_rev.type_cell_data,
            &field_rev,
            Some(self.cell_data_cache.clone()),
        ))
    }

    pub async fn get_cell_rev(&self, row_id: &str, field_id: &str) -> FlowyResult<Option<CellRevision>> {
        match self.block_manager.get_row_rev(row_id).await? {
            None => Ok(None),
            Some((_, row_rev)) => {
                let cell_rev = row_rev.cells.get(field_id).cloned();
                Ok(cell_rev)
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn update_cell_with_changeset(&self, cell_changeset: CellChangesetPB) -> FlowyResult<()> {
        let CellChangesetPB {
            grid_id,
            row_id,
            field_id,
            type_cell_data: mut content,
        } = cell_changeset;

        match self.grid_pad.read().await.get_field_rev(&field_id) {
            None => {
                let msg = format!("Field:{} not found", &field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some((_, field_rev)) => {
                tracing::trace!("field changeset: id:{} / value:{:?}", &field_id, content);
                let cell_rev = self.get_cell_rev(&row_id, &field_id).await?;
                // Update the changeset.data property with the return value.
                content = apply_cell_data_changeset(content, cell_rev, field_rev, Some(self.cell_data_cache.clone()))?;
                let cell_changeset = CellChangesetPB {
                    grid_id,
                    row_id: row_id.clone(),
                    field_id: field_id.clone(),
                    type_cell_data: content,
                };
                let _ = self.block_manager.update_cell(cell_changeset).await?;
                self.view_manager.did_update_cell(&row_id).await;
                Ok(())
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn update_cell<T: ToString>(
        &self,
        grid_id: String,
        row_id: String,
        field_id: String,
        content: T,
    ) -> FlowyResult<()> {
        self.update_cell_with_changeset(CellChangesetPB {
            grid_id,
            row_id,
            field_id,
            type_cell_data: content.to_string(),
        })
        .await
    }

    pub async fn get_block_meta_revs(&self) -> FlowyResult<Vec<Arc<GridBlockMetaRevision>>> {
        let block_meta_revs = self.grid_pad.read().await.get_block_meta_revs();
        Ok(block_meta_revs)
    }

    pub async fn get_blocks(&self, block_ids: Option<Vec<String>>) -> FlowyResult<Vec<GridBlockRowRevision>> {
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
        let blocks = self.block_manager.get_blocks(Some(block_ids)).await?;
        Ok(blocks)
    }

    pub async fn delete_rows(&self, block_rows: Vec<GridBlockRow>) -> FlowyResult<()> {
        let changesets = self.block_manager.delete_rows(block_rows).await?;
        for changeset in changesets {
            let _ = self.update_block(changeset).await?;
        }
        Ok(())
    }

    pub async fn get_grid(&self, view_id: &str) -> FlowyResult<GridPB> {
        let pad = self.grid_pad.read().await;
        let fields = pad.get_field_revs(None)?.iter().map(FieldIdPB::from).collect();
        let mut all_rows = vec![];
        for block_rev in pad.get_block_meta_revs() {
            if let Ok(rows) = self.get_row_pbs(view_id, &block_rev.block_id).await {
                all_rows.extend(rows);
            }
        }

        Ok(GridPB {
            id: self.grid_id.clone(),
            fields,
            rows: all_rows,
        })
    }

    pub async fn get_setting(&self) -> FlowyResult<GridSettingPB> {
        self.view_manager.get_setting().await
    }

    pub async fn get_all_filters(&self) -> FlowyResult<Vec<FilterPB>> {
        Ok(self
            .view_manager
            .get_all_filters()
            .await?
            .into_iter()
            .map(|filter| FilterPB::from(filter.as_ref()))
            .collect())
    }

    pub async fn get_filters(&self, filter_id: FilterType) -> FlowyResult<Vec<Arc<FilterRevision>>> {
        self.view_manager.get_filters(&filter_id).await
    }

    pub async fn insert_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
        self.view_manager.insert_or_update_group(params).await
    }

    pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
        self.view_manager.delete_group(params).await
    }

    pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
        let _ = self.view_manager.create_or_update_filter(params).await?;
        Ok(())
    }

    pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
        let _ = self.view_manager.delete_filter(params).await?;
        Ok(())
    }

    pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
        let _ = self.view_manager.delete_sort(params).await?;
        Ok(())
    }

    pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<SortRevision> {
        let sort_rev = self.view_manager.create_or_update_sort(params).await?;
        Ok(sort_rev)
    }

    pub async fn move_row(&self, params: MoveRowParams) -> FlowyResult<()> {
        let MoveRowParams {
            view_id: _,
            from_row_id,
            to_row_id,
        } = params;

        match self.block_manager.get_row_rev(&from_row_id).await? {
            None => tracing::warn!("Move row failed, can not find the row:{}", from_row_id),
            Some((_, row_rev)) => {
                match (
                    self.block_manager.index_of_row(&from_row_id).await,
                    self.block_manager.index_of_row(&to_row_id).await,
                ) {
                    (Some(from_index), Some(to_index)) => {
                        tracing::trace!("Move row from {} to {}", from_index, to_index);
                        let _ = self
                            .block_manager
                            .move_row(row_rev.clone(), from_index, to_index)
                            .await?;
                    }
                    (_, None) => tracing::warn!("Can not find the from row id: {}", from_row_id),
                    (None, _) => tracing::warn!("Can not find the to row id: {}", to_row_id),
                }
            }
        }
        Ok(())
    }

    pub async fn move_group_row(&self, params: MoveGroupRowParams) -> FlowyResult<()> {
        let MoveGroupRowParams {
            view_id,
            from_row_id,
            to_group_id,
            to_row_id,
        } = params;

        match self.block_manager.get_row_rev(&from_row_id).await? {
            None => tracing::warn!("Move row failed, can not find the row:{}", from_row_id),
            Some((_, row_rev)) => {
                let block_manager = self.block_manager.clone();
                self.view_manager
                    .move_group_row(row_rev, to_group_id, to_row_id.clone(), |row_changeset| {
                        to_fut(async move {
                            tracing::trace!("Row data changed: {:?}", row_changeset);
                            let cell_changesets = row_changeset
                                .cell_by_field_id
                                .into_iter()
                                .map(|(field_id, cell_rev)| CellChangesetPB {
                                    grid_id: view_id.clone(),
                                    row_id: row_changeset.row_id.clone(),
                                    field_id,
                                    type_cell_data: cell_rev.type_cell_data,
                                })
                                .collect::<Vec<CellChangesetPB>>();

                            for cell_changeset in cell_changesets {
                                match block_manager.update_cell(cell_changeset).await {
                                    Ok(_) => {}
                                    Err(e) => tracing::error!("Apply cell changeset error:{:?}", e),
                                }
                            }
                        })
                    })
                    .await?;
            }
        }
        Ok(())
    }

    pub async fn move_field(&self, params: MoveFieldParams) -> FlowyResult<()> {
        let MoveFieldParams {
            grid_id: _,
            field_id,
            from_index,
            to_index,
        } = params;

        let _ = self
            .modify(|grid_pad| Ok(grid_pad.move_field(&field_id, from_index as usize, to_index as usize)?))
            .await?;
        if let Some((index, field_rev)) = self.grid_pad.read().await.get_field_rev(&field_id) {
            let delete_field_order = FieldIdPB::from(field_id);
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

    pub async fn duplicate_grid(&self) -> FlowyResult<BuildGridContext> {
        let grid_pad = self.grid_pad.read().await;
        let grid_view_revision_data = self.view_manager.duplicate_grid_view().await?;
        let original_blocks = grid_pad.get_block_meta_revs();
        let (duplicated_fields, duplicated_blocks) = grid_pad.duplicate_grid_block_meta().await;

        let mut blocks_meta_data = vec![];
        if original_blocks.len() == duplicated_blocks.len() {
            for (index, original_block_meta) in original_blocks.iter().enumerate() {
                let grid_block_meta_editor = self
                    .block_manager
                    .get_block_editor(&original_block_meta.block_id)
                    .await?;
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
            block_metas: duplicated_blocks,
            blocks: blocks_meta_data,
            grid_view_revision_data,
        })
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn load_groups(&self) -> FlowyResult<RepeatedGroupPB> {
        self.view_manager.load_groups().await
    }

    async fn create_row_rev(&self) -> FlowyResult<RowRevision> {
        let field_revs = self.grid_pad.read().await.get_field_revs(None)?;
        let block_id = self.block_id().await?;

        // insert empty row below the row whose id is upper_row_id
        let row_rev = RowRevisionBuilder::new(&block_id, &field_revs).build();
        Ok(row_rev)
    }

    async fn create_row_pb(&self, row_rev: RowRevision, start_row_id: Option<String>) -> FlowyResult<RowPB> {
        let row_pb = RowPB::from(&row_rev);
        let block_id = row_rev.block_id.clone();

        // insert the row
        let row_count = self.block_manager.create_row(row_rev, start_row_id).await?;

        // update block row count
        let changeset = GridBlockMetaRevisionChangeset::from_row_count(block_id, row_count);
        let _ = self.update_block(changeset).await?;
        Ok(row_pb)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridRevisionPad) -> FlowyResult<Option<GridRevisionChangeset>>,
    {
        let mut write_guard = self.grid_pad.write().await;
        if let Some(changeset) = f(&mut *write_guard)? {
            let _ = self.apply_change(changeset).await?;
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridRevisionChangeset) -> FlowyResult<()> {
        let GridRevisionChangeset { operations: delta, md5 } = change;
        let data = delta.json_bytes();
        let _ = self.rev_manager.add_local_revision(data, md5).await?;
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
            let updated_field = FieldPB::from(field_rev);
            let notified_changeset = GridFieldChangesetPB::update(&self.grid_id, vec![updated_field.clone()]);
            let _ = self.notify_did_update_grid(notified_changeset).await?;

            send_dart_notification(field_id, GridDartNotification::DidUpdateField)
                .payload(updated_field)
                .send();
        }

        Ok(())
    }

    async fn notify_did_update_grid(&self, changeset: GridFieldChangesetPB) -> FlowyResult<()> {
        send_dart_notification(&self.grid_id, GridDartNotification::DidUpdateGridFields)
            .payload(changeset)
            .send();
        Ok(())
    }
}

#[cfg(feature = "flowy_unit_test")]
impl GridRevisionEditor {
    pub fn rev_manager(&self) -> Arc<RevisionManager<Arc<ConnectionPool>>> {
        self.rev_manager.clone()
    }

    pub fn grid_pad(&self) -> Arc<RwLock<GridRevisionPad>> {
        self.grid_pad.clone()
    }
}

pub struct GridRevisionSerde();
impl RevisionObjectDeserializer for GridRevisionSerde {
    type Output = GridRevisionPad;

    fn deserialize_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridRevisionPad::from_revisions(revisions)?;
        Ok(pad)
    }
}
impl RevisionObjectSerializer for GridRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
        Ok(operations.json_bytes())
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

pub struct GridRevisionMergeable();

impl RevisionMergeable for GridRevisionMergeable {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        GridRevisionSerde::combine_revisions(revisions)
    }
}

struct TypeOptionJsonDeserializer(FieldType);
impl JsonDeserializer for TypeOptionJsonDeserializer {
    fn deserialize(&self, type_option_data: Vec<u8>) -> CollaborateResult<String> {
        // The type_option_data sent from Dart is serialized by protobuf.
        let builder = type_option_builder_from_bytes(type_option_data, &self.0);
        let json = builder.serializer().json_str();
        tracing::trace!("Deserialize type-option data to: {}", json);
        Ok(json)
    }
}
