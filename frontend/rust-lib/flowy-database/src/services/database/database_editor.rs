use crate::entities::CellIdParams;
use crate::entities::*;
use crate::manager::DatabaseUser;
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::{
  apply_cell_data_changeset, get_type_cell_protobuf, stringify_cell_data, AnyTypeCache,
  AtomicCellDataCache, CellProtobufBlob, ToCellChangesetString, TypeCellData,
};
use crate::services::database::DatabaseBlocks;
use crate::services::field::{
  default_type_option_builder_from_type, transform_type_option, type_option_builder_from_bytes,
  FieldBuilder, RowSingleCellData,
};

use crate::services::database::DatabaseViewDataImpl;
use crate::services::database_view::{
  DatabaseViewChanged, DatabaseViewData, DatabaseViewEditor, DatabaseViews,
};
use crate::services::filter::FilterType;
use crate::services::persistence::block_index::BlockRowIndexer;
use crate::services::persistence::database_ref::DatabaseViewRef;
use crate::services::row::{DatabaseBlockRow, DatabaseBlockRowRevision, RowRevisionBuilder};
use bytes::Bytes;
use database_model::*;
use flowy_client_sync::client_database::{
  DatabaseRevisionChangeset, DatabaseRevisionPad, JsonDeserializer,
};
use flowy_client_sync::errors::{SyncError, SyncResult};
use flowy_client_sync::make_operations_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{
  RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer,
  RevisionObjectSerializer,
};
use flowy_sqlite::ConnectionPool;
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, FutureResult};
use lib_ot::core::EmptyAttributes;
use revision_model::Revision;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub trait DatabaseRefIndexerQuery: Send + Sync + 'static {
  fn get_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseViewRef>>;
}

pub struct DatabaseEditor {
  pub database_id: String,
  database_pad: Arc<RwLock<DatabaseRevisionPad>>,
  rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
  database_views: Arc<DatabaseViews>,
  database_blocks: Arc<DatabaseBlocks>,
  pub database_view_data: Arc<dyn DatabaseViewData>,
  pub cell_data_cache: AtomicCellDataCache,
  database_ref_query: Arc<dyn DatabaseRefIndexerQuery>,
}

impl Drop for DatabaseEditor {
  fn drop(&mut self) {
    tracing::trace!("Drop DatabaseRevisionEditor");
  }
}

impl DatabaseEditor {
  #[allow(clippy::too_many_arguments)]
  pub async fn new(
    database_id: &str,
    user: Arc<dyn DatabaseUser>,
    database_pad: Arc<RwLock<DatabaseRevisionPad>>,
    rev_manager: RevisionManager<Arc<ConnectionPool>>,
    persistence: Arc<BlockRowIndexer>,
    database_ref_query: Arc<dyn DatabaseRefIndexerQuery>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Arc<Self>> {
    let rev_manager = Arc::new(rev_manager);
    let cell_data_cache = AnyTypeCache::<u64>::new();

    // Block manager
    let (block_event_tx, block_event_rx) = broadcast::channel(100);
    let block_meta_revs = database_pad.read().await.get_block_meta_revs();
    let database_blocks =
      Arc::new(DatabaseBlocks::new(&user, block_meta_revs, persistence, block_event_tx).await?);

    let database_view_data = Arc::new(DatabaseViewDataImpl {
      pad: database_pad.clone(),
      blocks: database_blocks.clone(),
      task_scheduler,
      cell_data_cache: cell_data_cache.clone(),
    });

    // View manager
    let database_views = DatabaseViews::new(
      user.clone(),
      database_view_data.clone(),
      cell_data_cache.clone(),
      block_event_rx,
    )
    .await?;
    let database_views = Arc::new(database_views);
    let editor = Arc::new(Self {
      database_id: database_id.to_owned(),
      database_pad,
      rev_manager,
      database_blocks,
      database_views,
      cell_data_cache,
      database_ref_query,
      database_view_data,
    });

    Ok(editor)
  }

  pub async fn open_view_editor(&self, view_editor: DatabaseViewEditor) {
    self.database_views.open(view_editor).await
  }

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_view_editor(&self, view_id: &str) {
    self.database_views.close(view_id).await;
  }

  pub async fn dispose(&self) {
    self.rev_manager.generate_snapshot().await;
    self.database_blocks.close().await;
    self.rev_manager.close().await;
  }

  pub async fn number_of_ref_views(&self) -> usize {
    self.database_views.number_of_views().await
  }

  pub async fn is_view_open(&self, view_id: &str) -> bool {
    self.database_views.is_view_exist(view_id).await
  }
  /// Save the type-option data to disk and send a `DatabaseNotification::DidUpdateField` notification
  /// to dart side.
  ///
  /// It will do nothing if the passed-in type_option_data is empty
  /// # Arguments
  ///
  /// * `field_id`: the id of the field
  /// * `type_option_data`: the updated type-option data. The `type-option` data might be empty
  /// if there is no type-option config for that field. For example, the `RichTextTypeOptionPB`.
  ///  
  pub async fn update_field_type_option(
    &self,
    view_id: &str,
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
    self
      .modify(|pad| {
        let changeset = pad.modify_field(field_id, |field| {
          let deserializer = TypeOptionJsonDeserializer(field_rev.ty.into());
          match deserializer.deserialize(type_option_data) {
            Ok(json_str) => {
              let field_type = field.ty;
              field.insert_type_option_str(&field_type, json_str);
            },
            Err(err) => {
              tracing::error!("Deserialize data to type option json failed: {}", err);
            },
          }
          Ok(Some(()))
        })?;
        Ok(changeset)
      })
      .await?;

    self
      .database_views
      .did_update_field_type_option(view_id, field_id, old_field_rev)
      .await?;
    self.notify_did_update_database_field(field_id).await?;
    Ok(())
  }

  pub async fn next_field_rev(&self, field_type: &FieldType) -> FlowyResult<FieldRevision> {
    let name = format!(
      "Property {}",
      self.database_pad.read().await.get_fields().len() + 1
    );
    let field_rev = FieldBuilder::from_field_type(field_type)
      .name(&name)
      .build();
    Ok(field_rev)
  }

  pub async fn create_new_field_rev(&self, field_rev: FieldRevision) -> FlowyResult<()> {
    let field_id = field_rev.id.clone();
    self
      .modify(|pad| Ok(pad.create_field_rev(field_rev, None)?))
      .await?;
    self.notify_did_insert_database_field(&field_id).await?;

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
    self
      .modify(|pad| Ok(pad.create_field_rev(field_rev.clone(), None)?))
      .await?;
    self.notify_did_insert_database_field(&field_rev.id).await?;

    Ok(field_rev)
  }

  pub async fn contain_field(&self, field_id: &str) -> bool {
    self.database_pad.read().await.contain_field(field_id)
  }

  pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
    let field_id = params.field_id.clone();
    self
      .modify(|pad| {
        let changeset = pad.modify_field(&params.field_id, |field| {
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
    self.notify_did_update_database_field(&field_id).await?;
    Ok(())
  }

  pub async fn modify_field_rev<F>(&self, view_id: &str, field_id: &str, f: F) -> FlowyResult<()>
  where
    F: for<'a> FnOnce(&'a mut FieldRevision) -> FlowyResult<Option<()>>,
  {
    let mut is_changed = false;
    let old_field_rev = self.get_field_rev(field_id).await;
    self
      .modify(|pad| {
        let changeset = pad.modify_field(field_id, |field_rev| {
          f(field_rev).map_err(|e| SyncError::internal().context(e))
        })?;
        is_changed = changeset.is_some();
        Ok(changeset)
      })
      .await?;

    if is_changed {
      match self
        .database_views
        .did_update_field_type_option(view_id, field_id, old_field_rev)
        .await
      {
        Ok(_) => {},
        Err(e) => tracing::error!("View manager update field failed: {:?}", e),
      }
      self.notify_did_update_database_field(field_id).await?;
    }
    Ok(())
  }

  pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
    self
      .modify(|pad| Ok(pad.delete_field_rev(field_id)?))
      .await?;
    let field_order = FieldIdPB::from(field_id);
    let notified_changeset = DatabaseFieldChangesetPB::delete(&self.database_id, vec![field_order]);
    self.notify_did_update_database(notified_changeset).await?;
    Ok(())
  }

  pub async fn group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    self
      .database_views
      .group_by_field(view_id, field_id)
      .await?;
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
  pub async fn switch_to_field_type(
    &self,
    field_id: &str,
    new_field_type: &FieldType,
  ) -> FlowyResult<()> {
    //
    let make_default_type_option = || -> String {
      return default_type_option_builder_from_type(new_field_type)
        .serializer()
        .json_str();
    };

    let type_option_transform = |old_field_type: FieldTypeRevision,
                                 old_type_option: Option<String>,
                                 new_type_option: String| {
      let old_field_type: FieldType = old_field_type.into();
      transform_type_option(
        &new_type_option,
        new_field_type,
        old_type_option,
        old_field_type,
      )
    };

    self
      .modify(|pad| {
        Ok(pad.switch_to_field(
          field_id,
          new_field_type.clone(),
          make_default_type_option,
          type_option_transform,
        )?)
      })
      .await?;

    self.notify_did_update_database_field(field_id).await?;

    Ok(())
  }

  pub async fn duplicate_field(&self, field_id: &str) -> FlowyResult<()> {
    let duplicated_field_id = gen_field_id();
    self
      .modify(|pad| Ok(pad.duplicate_field_rev(field_id, &duplicated_field_id)?))
      .await?;

    self
      .notify_did_insert_database_field(&duplicated_field_id)
      .await?;
    Ok(())
  }

  pub async fn get_field_rev(&self, field_id: &str) -> Option<Arc<FieldRevision>> {
    let field_rev = self
      .database_pad
      .read()
      .await
      .get_field_rev(field_id)?
      .1
      .clone();
    Some(field_rev)
  }

  pub async fn get_field_revs(
    &self,
    field_ids: Option<Vec<String>>,
  ) -> FlowyResult<Vec<Arc<FieldRevision>>> {
    if field_ids.is_none() {
      let field_revs = self.database_pad.read().await.get_field_revs(None)?;
      return Ok(field_revs);
    }

    let field_ids = field_ids.unwrap_or_default();
    let expected_len = field_ids.len();
    let field_revs = self
      .database_pad
      .read()
      .await
      .get_field_revs(Some(field_ids))?;
    if expected_len != 0 && field_revs.len() != expected_len {
      tracing::error!(
        "This is a bug. The len of the field_revs should equal to {}",
        expected_len
      );
      debug_assert!(field_revs.len() == expected_len);
    }
    Ok(field_revs)
  }

  pub async fn create_block(&self, block_meta_rev: DatabaseBlockMetaRevision) -> FlowyResult<()> {
    self
      .modify(|pad| Ok(pad.create_block_meta_rev(block_meta_rev)?))
      .await?;
    Ok(())
  }

  pub async fn update_block(
    &self,
    changeset: DatabaseBlockMetaRevisionChangeset,
  ) -> FlowyResult<()> {
    self
      .modify(|pad| Ok(pad.update_block_rev(changeset)?))
      .await?;
    Ok(())
  }

  pub async fn create_row(&self, params: CreateRowParams) -> FlowyResult<RowPB> {
    let mut row_rev = self
      .create_row_rev(params.cell_data_by_field_id.clone())
      .await?;

    self
      .database_views
      .will_create_row(&mut row_rev, &params)
      .await;

    let row_pb = self
      .create_row_pb(row_rev, params.start_row_id.clone())
      .await?;

    self.database_views.did_create_row(&row_pb, &params).await;
    Ok(row_pb)
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
    self.database_views.move_group(params).await?;
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
    let changesets = self.database_blocks.insert_row(rows_by_block_id).await?;
    for changeset in changesets {
      self.update_block(changeset).await?;
    }
    Ok(row_orders)
  }

  pub async fn update_row(&self, changeset: RowChangeset) -> FlowyResult<()> {
    let row_id = changeset.row_id.clone();
    let old_row = self.get_row_rev(&row_id).await?;
    self.database_blocks.update_row(changeset).await?;
    self.database_views.did_update_row(old_row, &row_id).await;
    Ok(())
  }

  /// Returns all the rows in this block.
  pub async fn get_row_pbs(&self, view_id: &str, block_id: &str) -> FlowyResult<Vec<RowPB>> {
    let rows = self.database_views.get_row_revs(view_id, block_id).await?;
    let rows = rows
      .into_iter()
      .map(|row_rev| RowPB::from(&row_rev))
      .collect();
    Ok(rows)
  }

  pub async fn get_all_row_revs(&self, view_id: &str) -> FlowyResult<Vec<Arc<RowRevision>>> {
    let mut all_rows = vec![];
    let blocks = self.database_blocks.get_blocks(None).await?;
    for block in blocks {
      let rows = self
        .database_views
        .get_row_revs(view_id, &block.block_id)
        .await?;
      all_rows.extend(rows);
    }
    Ok(all_rows)
  }

  pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
    match self.database_blocks.get_row_rev(row_id).await? {
      None => Ok(None),
      Some((_, row_rev)) => Ok(Some(row_rev)),
    }
  }

  pub async fn delete_row(&self, row_id: &str) -> FlowyResult<()> {
    let row_rev = self.database_blocks.delete_row(row_id).await?;
    tracing::trace!("Did delete row:{:?}", row_rev);
    if let Some(row_rev) = row_rev {
      self.database_views.did_delete_row(row_rev).await;
    }
    Ok(())
  }

  pub async fn subscribe_view_changed(
    &self,
    view_id: &str,
  ) -> FlowyResult<broadcast::Receiver<DatabaseViewChanged>> {
    self.database_views.subscribe_view_changed(view_id).await
  }

  pub async fn duplicate_row(&self, _row_id: &str) -> FlowyResult<()> {
    Ok(())
  }

  /// Returns the cell data that encoded in protobuf.
  pub async fn get_cell(&self, params: &CellIdParams) -> Option<CellPB> {
    let (field_type, cell_bytes) = self.get_type_cell_protobuf(params).await?;
    Some(CellPB::new(
      &params.field_id,
      &params.row_id,
      field_type,
      cell_bytes.to_vec(),
    ))
  }

  /// Returns a string that represents the current field_type's cell data.
  /// For example:
  /// Multi-Select: list of the option's name separated by a comma.
  /// Number: 123 => $123 if the currency set.
  /// Date: 1653609600 => May 27,2022
  ///
  pub async fn get_cell_display_str(&self, params: &CellIdParams) -> String {
    let display_str = || async {
      let field_rev = self.get_field_rev(&params.field_id).await?;
      let field_type: FieldType = field_rev.ty.into();
      let cell_rev = self
        .get_cell_rev(&params.row_id, &params.field_id)
        .await
        .ok()??;
      let type_cell_data: TypeCellData = cell_rev.try_into().ok()?;
      Some(stringify_cell_data(
        type_cell_data.cell_str,
        &field_type,
        &field_type,
        &field_rev,
      ))
    };

    display_str().await.unwrap_or_default()
  }

  pub async fn get_cell_protobuf(&self, params: &CellIdParams) -> Option<CellProtobufBlob> {
    let (_, cell_data) = self.get_type_cell_protobuf(params).await?;
    Some(cell_data)
  }

  async fn get_type_cell_protobuf(
    &self,
    params: &CellIdParams,
  ) -> Option<(FieldType, CellProtobufBlob)> {
    let field_rev = self.get_field_rev(&params.field_id).await?;
    let (_, row_rev) = self
      .database_blocks
      .get_row_rev(&params.row_id)
      .await
      .ok()??;
    let cell_rev = row_rev.cells.get(&params.field_id)?.clone();
    Some(get_type_cell_protobuf(
      cell_rev.type_cell_data,
      &field_rev,
      Some(self.cell_data_cache.clone()),
    ))
  }

  pub async fn get_cell_rev(
    &self,
    row_id: &str,
    field_id: &str,
  ) -> FlowyResult<Option<CellRevision>> {
    match self.database_blocks.get_row_rev(row_id).await? {
      None => Ok(None),
      Some((_, row_rev)) => {
        let cell_rev = row_rev.cells.get(field_id).cloned();
        Ok(cell_rev)
      },
    }
  }

  /// Returns the list of cells corresponding to the given field.
  pub async fn get_cells_for_field(
    &self,
    view_id: &str,
    field_id: &str,
  ) -> FlowyResult<Vec<RowSingleCellData>> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_get_cells_for_field(field_id).await
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn update_cell_with_changeset<T: ToCellChangesetString>(
    &self,
    row_id: &str,
    field_id: &str,
    cell_changeset: T,
  ) -> FlowyResult<()> {
    match self.database_pad.read().await.get_field_rev(field_id) {
      None => {
        let msg = format!("Field with id:{} not found", &field_id);
        Err(FlowyError::internal().context(msg))
      },
      Some((_, field_rev)) => {
        tracing::trace!(
          "Cell changeset: id:{} / value:{:?}",
          &field_id,
          cell_changeset
        );
        let old_row_rev = self.get_row_rev(row_id).await?.clone();
        let cell_rev = self.get_cell_rev(row_id, field_id).await?;
        // Update the changeset.data property with the return value.
        let type_cell_data = apply_cell_data_changeset(
          cell_changeset,
          cell_rev,
          field_rev,
          Some(self.cell_data_cache.clone()),
        )?;
        let cell_changeset = CellChangesetPB {
          view_id: self.database_id.clone(),
          row_id: row_id.to_owned(),
          field_id: field_id.to_owned(),
          type_cell_data,
        };
        self.database_blocks.update_cell(cell_changeset).await?;
        self
          .database_views
          .did_update_row(old_row_rev, row_id)
          .await;
        Ok(())
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn update_cell<T: ToCellChangesetString>(
    &self,
    row_id: String,
    field_id: String,
    cell_changeset: T,
  ) -> FlowyResult<()> {
    self
      .update_cell_with_changeset(&row_id, &field_id, cell_changeset)
      .await
  }

  pub async fn get_block_meta_revs(&self) -> FlowyResult<Vec<Arc<DatabaseBlockMetaRevision>>> {
    let block_meta_revs = self.database_pad.read().await.get_block_meta_revs();
    Ok(block_meta_revs)
  }

  pub async fn get_blocks(
    &self,
    block_ids: Option<Vec<String>>,
  ) -> FlowyResult<Vec<DatabaseBlockRowRevision>> {
    let block_ids = match block_ids {
      None => self
        .database_pad
        .read()
        .await
        .get_block_meta_revs()
        .iter()
        .map(|block_rev| block_rev.block_id.clone())
        .collect::<Vec<String>>(),
      Some(block_ids) => block_ids,
    };
    let blocks = self.database_blocks.get_blocks(Some(block_ids)).await?;
    Ok(blocks)
  }

  pub async fn delete_rows(&self, block_rows: Vec<DatabaseBlockRow>) -> FlowyResult<()> {
    let changesets = self.database_blocks.delete_rows(block_rows).await?;
    for changeset in changesets {
      self.update_block(changeset).await?;
    }
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn get_database(&self, view_id: &str) -> FlowyResult<DatabasePB> {
    let pad = self.database_pad.read().await;
    let fields = pad
      .get_field_revs(None)?
      .iter()
      .map(FieldIdPB::from)
      .collect();
    let mut all_rows = vec![];
    for block_rev in pad.get_block_meta_revs() {
      if let Ok(rows) = self.get_row_pbs(view_id, &block_rev.block_id).await {
        all_rows.extend(rows);
      }
    }

    Ok(DatabasePB {
      id: self.database_id.clone(),
      fields,
      rows: all_rows,
    })
  }

  pub async fn get_setting(&self, view_id: &str) -> FlowyResult<DatabaseViewSettingPB> {
    self.database_views.get_setting(view_id).await
  }

  pub async fn get_all_filters(&self, view_id: &str) -> FlowyResult<Vec<FilterPB>> {
    Ok(
      self
        .database_views
        .get_all_filters(view_id)
        .await?
        .into_iter()
        .map(|filter| FilterPB::from(filter.as_ref()))
        .collect(),
    )
  }

  pub async fn get_filters(
    &self,
    view_id: &str,
    filter_id: FilterType,
  ) -> FlowyResult<Vec<Arc<FilterRevision>>> {
    self.database_views.get_filters(view_id, &filter_id).await
  }

  pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
    self.database_views.create_or_update_filter(params).await?;
    Ok(())
  }

  pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    self.database_views.delete_filter(params).await?;
    Ok(())
  }

  pub async fn get_all_sorts(&self, view_id: &str) -> FlowyResult<Vec<SortPB>> {
    Ok(
      self
        .database_views
        .get_all_sorts(view_id)
        .await?
        .into_iter()
        .map(|sort| SortPB::from(sort.as_ref()))
        .collect(),
    )
  }

  pub async fn delete_all_sorts(&self, view_id: &str) -> FlowyResult<()> {
    self.database_views.delete_all_sorts(view_id).await
  }

  pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    self.database_views.delete_sort(params).await?;
    Ok(())
  }

  pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<SortRevision> {
    let sort_rev = self.database_views.create_or_update_sort(params).await?;
    Ok(sort_rev)
  }

  pub async fn insert_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    self.database_views.insert_or_update_group(params).await
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self.database_views.delete_group(params).await
  }

  pub async fn move_row(&self, params: MoveRowParams) -> FlowyResult<()> {
    let MoveRowParams {
      view_id: _,
      from_row_id,
      to_row_id,
    } = params;

    match self.database_blocks.get_row_rev(&from_row_id).await? {
      None => tracing::warn!("Move row failed, can not find the row:{}", from_row_id),
      Some((_, row_rev)) => {
        match (
          self.database_blocks.index_of_row(&from_row_id).await,
          self.database_blocks.index_of_row(&to_row_id).await,
        ) {
          (Some(from_index), Some(to_index)) => {
            tracing::trace!("Move row from {} to {}", from_index, to_index);
            self
              .database_blocks
              .move_row(row_rev.clone(), from_index, to_index)
              .await?;
          },
          (_, None) => tracing::warn!("Can not find the from row id: {}", from_row_id),
          (None, _) => tracing::warn!("Can not find the to row id: {}", to_row_id),
        }
      },
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

    match self.database_blocks.get_row_rev(&from_row_id).await? {
      None => tracing::warn!("Move row failed, can not find the row:{}", from_row_id),
      Some((_, row_rev)) => {
        let block_manager = self.database_blocks.clone();
        self
          .database_views
          .move_group_row(
            &view_id.clone(),
            row_rev,
            to_group_id,
            to_row_id.clone(),
            |row_changeset| {
              to_fut(async move {
                tracing::trace!("Row data changed: {:?}", row_changeset);
                let cell_changesets = row_changeset
                  .cell_by_field_id
                  .into_iter()
                  .map(|(field_id, cell_rev)| CellChangesetPB {
                    view_id: view_id.clone(),
                    row_id: row_changeset.row_id.clone(),
                    field_id,
                    type_cell_data: cell_rev.type_cell_data,
                  })
                  .collect::<Vec<CellChangesetPB>>();

                for cell_changeset in cell_changesets {
                  match block_manager.update_cell(cell_changeset).await {
                    Ok(_) => {},
                    Err(e) => tracing::error!("Apply cell changeset error:{:?}", e),
                  }
                }
              })
            },
          )
          .await?;
      },
    }
    Ok(())
  }

  pub async fn move_field(&self, params: MoveFieldParams) -> FlowyResult<()> {
    let MoveFieldParams {
      view_id: _,
      field_id,
      from_index,
      to_index,
    } = params;

    self
      .modify(|pad| Ok(pad.move_field(&field_id, from_index as usize, to_index as usize)?))
      .await?;
    if let Some((index, field_rev)) = self.database_pad.read().await.get_field_rev(&field_id) {
      let delete_field_order = FieldIdPB::from(field_id);
      let insert_field = IndexFieldPB::from_field_rev(field_rev, index);
      let notified_changeset = DatabaseFieldChangesetPB {
        view_id: self.database_id.clone(),
        inserted_fields: vec![insert_field],
        deleted_fields: vec![delete_field_order],
        updated_fields: vec![],
      };

      self.notify_did_update_database(notified_changeset).await?;
    }
    Ok(())
  }

  pub async fn duplicate_database(&self, view_id: &str) -> FlowyResult<BuildDatabaseContext> {
    let database_pad = self.database_pad.read().await;
    let database_view_data = self.database_views.duplicate_database_view(view_id).await?;

    let original_blocks = database_pad.get_block_meta_revs();
    let (duplicated_fields, duplicated_blocks) = database_pad.duplicate_database_block_meta().await;

    let mut blocks_meta_data = vec![];
    if original_blocks.len() == duplicated_blocks.len() {
      for (index, original_block_meta) in original_blocks.iter().enumerate() {
        let database_block_meta_editor = self
          .database_blocks
          .get_or_create_block_editor(&original_block_meta.block_id)
          .await?;
        let duplicated_block_id = &duplicated_blocks[index].block_id;

        tracing::trace!("Duplicate block:{} meta data", duplicated_block_id);
        let duplicated_block_meta_data = database_block_meta_editor
          .duplicate_block(duplicated_block_id)
          .await;
        blocks_meta_data.push(duplicated_block_meta_data);
      }
    } else {
      debug_assert_eq!(original_blocks.len(), duplicated_blocks.len());
    }
    drop(database_pad);

    Ok(BuildDatabaseContext {
      field_revs: duplicated_fields.into_iter().map(Arc::new).collect(),
      block_metas: duplicated_blocks,
      blocks: blocks_meta_data,
      layout_setting: Default::default(),
      database_view_data,
    })
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn load_groups(&self, view_id: &str) -> FlowyResult<RepeatedGroupPB> {
    self.database_views.load_groups(view_id).await
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn get_group(&self, view_id: &str, group_id: &str) -> FlowyResult<GroupPB> {
    self.database_views.get_group(view_id, group_id).await
  }

  pub async fn get_layout_setting<T: Into<LayoutRevision>>(
    &self,
    view_id: &str,
    layout_ty: T,
  ) -> FlowyResult<LayoutSettingParams> {
    let layout_ty = layout_ty.into();
    self
      .database_views
      .get_layout_setting(view_id, &layout_ty)
      .await
  }

  pub async fn set_layout_setting(
    &self,
    view_id: &str,
    layout_setting: LayoutSettingParams,
  ) -> FlowyResult<()> {
    self
      .database_views
      .set_layout_setting(view_id, layout_setting)
      .await
  }

  pub async fn get_all_calendar_events(&self, view_id: &str) -> Vec<CalendarEventPB> {
    match self.database_views.get_view_editor(view_id).await {
      Ok(view_editor) => view_editor
        .v_get_all_calendar_events()
        .await
        .unwrap_or_default(),
      Err(err) => {
        tracing::error!("Get calendar event failed: {}", err);
        vec![]
      },
    }
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn get_calendar_event(&self, view_id: &str, row_id: &str) -> Option<CalendarEventPB> {
    let view_editor = self.database_views.get_view_editor(view_id).await.ok()?;
    view_editor.v_get_calendar_event(row_id).await
  }

  async fn create_row_rev(
    &self,
    cell_data_by_field_id: Option<HashMap<String, String>>,
  ) -> FlowyResult<RowRevision> {
    let field_revs = self.database_pad.read().await.get_field_revs(None)?;
    let block_id = self.block_id().await?;

    // insert empty row below the row whose id is upper_row_id
    let builder = match cell_data_by_field_id {
      None => RowRevisionBuilder::new(&block_id, field_revs),
      Some(cell_data_by_field_id) => {
        RowRevisionBuilder::new_with_data(&block_id, field_revs, cell_data_by_field_id)
      },
    };

    let row_rev = builder.build();
    Ok(row_rev)
  }

  async fn create_row_pb(
    &self,
    row_rev: RowRevision,
    start_row_id: Option<String>,
  ) -> FlowyResult<RowPB> {
    let row_pb = RowPB::from(&row_rev);
    let block_id = row_rev.block_id.clone();

    // insert the row
    let row_count = self
      .database_blocks
      .create_row(row_rev, start_row_id)
      .await?;

    // update block row count
    let changeset = DatabaseBlockMetaRevisionChangeset::from_row_count(block_id, row_count);
    self.update_block(changeset).await?;
    Ok(row_pb)
  }

  async fn modify<F>(&self, f: F) -> FlowyResult<()>
  where
    F:
      for<'a> FnOnce(&'a mut DatabaseRevisionPad) -> FlowyResult<Option<DatabaseRevisionChangeset>>,
  {
    let mut write_guard = self.database_pad.write().await;
    if let Some(changeset) = f(&mut write_guard)? {
      self.apply_change(changeset).await?;
    }
    Ok(())
  }

  async fn apply_change(&self, change: DatabaseRevisionChangeset) -> FlowyResult<()> {
    let DatabaseRevisionChangeset {
      operations: delta,
      md5,
    } = change;
    let data = delta.json_bytes();
    let _ = self.rev_manager.add_local_revision(data, md5).await?;
    Ok(())
  }

  async fn block_id(&self) -> FlowyResult<String> {
    match self.database_pad.read().await.get_block_meta_revs().last() {
      None => Err(FlowyError::internal().context("There is no block in this database")),
      Some(database_block) => Ok(database_block.block_id.clone()),
    }
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_insert_database_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some((index, field_rev)) = self.database_pad.read().await.get_field_rev(field_id) {
      let index_field = IndexFieldPB::from_field_rev(field_rev, index);
      if let Ok(views) = self.database_ref_query.get_ref_views(&self.database_id) {
        for view in views {
          let notified_changeset =
            DatabaseFieldChangesetPB::insert(&view.view_id, vec![index_field.clone()]);
          self.notify_did_update_database(notified_changeset).await?;
        }
      }
    }
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_update_database_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some((_, field_rev)) = self
      .database_pad
      .read()
      .await
      .get_field_rev(field_id)
      .map(|(index, field)| (index, field.clone()))
    {
      let updated_field = FieldPB::from(field_rev);
      let notified_changeset =
        DatabaseFieldChangesetPB::update(&self.database_id, vec![updated_field.clone()]);
      self.notify_did_update_database(notified_changeset).await?;

      send_notification(field_id, DatabaseNotification::DidUpdateField)
        .payload(updated_field)
        .send();
    }

    Ok(())
  }

  async fn notify_did_update_database(
    &self,
    changeset: DatabaseFieldChangesetPB,
  ) -> FlowyResult<()> {
    if let Ok(views) = self.database_ref_query.get_ref_views(&self.database_id) {
      for view in views {
        send_notification(&view.view_id, DatabaseNotification::DidUpdateFields)
          .payload(changeset.clone())
          .send();
      }
    }

    Ok(())
  }
}

#[cfg(feature = "flowy_unit_test")]
impl DatabaseEditor {
  pub fn rev_manager(&self) -> Arc<RevisionManager<Arc<ConnectionPool>>> {
    self.rev_manager.clone()
  }

  pub fn database_pad(&self) -> Arc<RwLock<DatabaseRevisionPad>> {
    self.database_pad.clone()
  }
}

pub struct DatabaseRevisionSerde();
impl RevisionObjectDeserializer for DatabaseRevisionSerde {
  type Output = DatabaseRevisionPad;

  fn deserialize_revisions(
    _object_id: &str,
    revisions: Vec<Revision>,
  ) -> FlowyResult<Self::Output> {
    let pad = DatabaseRevisionPad::from_revisions(revisions)?;
    Ok(pad)
  }

  fn recover_from_revisions(_revisions: Vec<Revision>) -> Option<(Self::Output, i64)> {
    None
  }
}
impl RevisionObjectSerializer for DatabaseRevisionSerde {
  fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
    let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
    Ok(operations.json_bytes())
  }
}

pub struct DatabaseRevisionCloudService {
  #[allow(dead_code)]
  token: String,
}

impl DatabaseRevisionCloudService {
  pub fn new(token: String) -> Self {
    Self { token }
  }
}

impl RevisionCloudService for DatabaseRevisionCloudService {
  #[tracing::instrument(level = "trace", skip(self))]
  fn fetch_object(
    &self,
    _user_id: &str,
    _object_id: &str,
  ) -> FutureResult<Vec<Revision>, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}

pub struct DatabaseRevisionMergeable();

impl RevisionMergeable for DatabaseRevisionMergeable {
  fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
    DatabaseRevisionSerde::combine_revisions(revisions)
  }
}

struct TypeOptionJsonDeserializer(FieldType);
impl JsonDeserializer for TypeOptionJsonDeserializer {
  fn deserialize(&self, type_option_data: Vec<u8>) -> SyncResult<String> {
    // The type_option_data sent from Dart is serialized by protobuf.
    let builder = type_option_builder_from_bytes(type_option_data, &self.0);
    let json = builder.serializer().json_str();
    tracing::trace!("Deserialize type-option data to: {}", json);
    Ok(json)
  }
}
