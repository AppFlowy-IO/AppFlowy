use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use bytes::Bytes;
use collab_database::database::{gen_row_id, timestamp, Database as InnerDatabase};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, Row, RowCell, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting, RowOrder};
use parking_lot::Mutex;
use tokio::sync::{broadcast, RwLock};

use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};

use crate::entities::{
  AlterFilterParams, AlterSortParams, CalendarEventPB, CellChangesetPB, CellPB, CreateRowParams,
  DatabaseFieldChangesetPB, DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB,
  DeleteFilterParams, DeleteGroupParams, DeleteSortParams, FieldChangesetParams, FieldIdPB,
  FieldPB, FieldType, FilterPB, GroupPB, GroupSettingPB, IndexFieldPB, InsertGroupParams,
  LayoutSettingPB, LayoutSettingParams, RepeatedFieldPB, RepeatedFilterPB, RepeatedGroupPB,
  RepeatedGroupSettingPB, RepeatedSortPB, RowPB, SelectOptionCellDataPB, SelectOptionPB, SortPB,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::{
  apply_cell_data_changeset, get_type_cell_protobuf, AnyTypeCache, CellBuilder, CellCache,
  ToCellChangeset,
};
use crate::services::database::util::{database_view_setting_pb_from_view, get_database_data};
use crate::services::database::{DatabaseRowEvent, InsertedRow, UpdatedRow};
use crate::services::database_view::{DatabaseViewData, DatabaseViews, RowEventSender};
use crate::services::field::{
  default_type_option_data_for_type, default_type_option_data_from_type,
  select_type_option_from_field, transform_type_option, type_option_data_from_pb_or_default,
  type_option_to_pb, SelectOptionCellChangeset, SelectOptionIds, TypeOptionCellDataHandler,
};
use crate::services::filter::Filter;
use crate::services::group::{default_group_setting, GroupSetting, RowChangeset};
use crate::services::sort::Sort;

#[derive(Clone)]
pub struct DatabaseEditor {
  database: MutexDatabase,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
  row_event_tx: RowEventSender,
}

impl DatabaseEditor {
  pub async fn new(
    database: MutexDatabase,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let cell_cache = AnyTypeCache::<u64>::new();
    let (row_event_tx, row_event_rx) = broadcast::channel(100);
    let database_view_data = Arc::new(DatabaseViewDataImpl {
      database: database.clone(),
      task_scheduler: task_scheduler.clone(),
    });

    let database_views = Arc::new(
      DatabaseViews::new(
        database.clone(),
        cell_cache.clone(),
        database_view_data,
        row_event_rx,
      )
      .await?,
    );
    Ok(Self {
      database,
      cell_cache,
      database_views,
      row_event_tx,
    })
  }

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_view_editor(&self, view_id: &str) -> bool {
    self.database_views.close_view(view_id).await
  }

  pub async fn close(&self) {}

  pub fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.lock().fields.get_field(field_id)
  }

  pub async fn insert_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if let Some(field) = self.database.lock().fields.get_field(&params.field_id) {
      let group_setting = default_group_setting(&field);
      self
        .database
        .lock()
        .insert_group_setting(&params.view_id, group_setting);
    }
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_initialize_new_group(params).await?;
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .delete_group_setting(&params.view_id, &params.group_id);
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_group(params).await?;

    Ok(())
  }

  pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_insert_filter(params).await?;
    Ok(())
  }

  pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_filter(params).await?;
    Ok(())
  }

  pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<Sort> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let sort = view_editor.v_insert_sort(params).await?;
    Ok(sort)
  }

  pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_sort(params).await?;
    Ok(())
  }

  pub async fn get_all_filters(&self, view_id: &str) -> RepeatedFilterPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_filters().await.into()
    } else {
      RepeatedFilterPB { items: vec![] }
    }
  }

  pub async fn get_all_sorts(&self, view_id: &str) -> RepeatedSortPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_sorts().await.into()
    } else {
      RepeatedSortPB { items: vec![] }
    }
  }

  pub async fn delete_all_sorts(&self, view_id: &str) {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      let _ = view_editor.v_delete_all_sorts().await;
    }
  }

  pub async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> RepeatedFieldPB {
    let fields = self.database.lock().get_fields(view_id, field_ids);
    fields
      .into_iter()
      .map(FieldPB::from)
      .collect::<Vec<FieldPB>>()
      .into()
  }

  pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .fields
      .update_field(&params.field_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_field_type_if_not_none(params.field_type.map(|field_type| field_type.into()))
          .set_width_at_if_not_none(params.width.map(|value| value as i64))
          .set_visibility_if_not_none(params.visibility);
      });
    self
      .notify_did_update_database_field(&params.field_id)
      .await?;
    Ok(())
  }

  pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
    self.database.lock().delete_field(field_id);
    let database_id = {
      let database = self.database.lock();
      database.delete_field(field_id);
      database.get_database_id()
    };
    let notified_changeset =
      DatabaseFieldChangesetPB::delete(&database_id, vec![FieldIdPB::from(field_id)]);
    self.notify_did_update_database(notified_changeset).await?;
    Ok(())
  }

  pub async fn update_field_type_option(
    &self,
    view_id: &str,
    field_id: &str,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FlowyResult<()> {
    let field_type = FieldType::from(old_field.field_type);
    self
      .database
      .lock()
      .fields
      .update_field(field_id, |update| {
        update.update_type_options(|type_options_update| {
          type_options_update.insert(&field_type.to_string(), type_option_data);
        });
      });
    self
      .database_views
      .did_update_field_type_option(view_id, field_id, &old_field)
      .await?;
    let _ = self.notify_did_update_database_field(field_id).await;
    Ok(())
  }

  pub async fn switch_to_field_type(
    &self,
    field_id: &str,
    new_field_type: &FieldType,
  ) -> FlowyResult<()> {
    match self.database.lock().fields.get_field(field_id) {
      None => {},
      Some(field) => {
        let old_field_type = FieldType::from(field.field_type);
        let old_type_option = field.get_any_type_option(old_field_type.clone());
        let new_type_option = field
          .get_any_type_option(new_field_type)
          .unwrap_or_else(|| default_type_option_data_for_type(new_field_type));

        let transformed_type_option = transform_type_option(
          &new_type_option,
          new_field_type,
          old_type_option,
          old_field_type,
        );
        self
          .database
          .lock()
          .fields
          .update_field(field_id, |update| {
            update.set_type_option(new_field_type.into(), Some(transformed_type_option));
          });
      },
    }

    self.notify_did_update_database_field(field_id).await?;
    Ok(())
  }

  pub async fn duplicate_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let value = self
      .database
      .lock()
      .duplicate_field(view_id, field_id, |field| format!("{} (copy)", field.name));
    if let Some((index, duplicated_field)) = value {
      let _ = self
        .notify_did_insert_database_field(duplicated_field, index)
        .await;
    }
    Ok(())
  }

  pub async fn duplicate_row(&self, view_id: &str, row_id: RowId) {
    let _ = self.database.lock().duplicate_row(view_id, row_id);
  }

  pub async fn move_row(&self, _view_id: &str, _from: RowId, _to: RowId) {
    // self.database.lock().views.update_view(view_id, |view| {
    //   view.move_row_order(from as u32, to as u32);
    // });
    // self.row_event_tx.send(DatabaseRowEvent::Move { from: _from, to: _to})
  }

  pub async fn create_row(&self, params: CreateRowParams) -> FlowyResult<Option<Row>> {
    let fields = self.database.lock().get_fields(&params.view_id, None);
    let mut cells =
      CellBuilder::with_cells(params.cell_data_by_field_id.unwrap_or_default(), fields).build();
    for view in self.database_views.editors().await {
      view.v_will_create_row(&mut cells, &params.group_id).await;
    }

    let result = self.database.lock().create_row_in_view(
      &params.view_id,
      collab_database::block::CreateRowParams {
        id: gen_row_id(),
        cells,
        height: 60,
        visibility: true,
        prev_row_id: params.start_row_id,
        timestamp: timestamp(),
      },
    );

    if let Some((index, row_order)) = result {
      let _ = self
        .row_event_tx
        .send(DatabaseRowEvent::InsertRow(InsertedRow {
          row: row_order.clone(),
          index: Some(index as i32),
          is_new: true,
        }));

      let row = self.database.lock().get_row(row_order.id);
      if let Some(row) = row {
        for view in self.database_views.editors().await {
          view.v_did_create_row(&row, &params.group_id, index).await;
        }
        return Ok(Some(row));
      }
    }

    Ok(None)
  }

  pub async fn get_field_type_option_data(&self, field_id: &str) -> Option<(Field, Bytes)> {
    let field = self.database.lock().fields.get_field(field_id);
    field.map(|field| {
      let field_type = FieldType::from(field.field_type);
      let type_option = field
        .get_any_type_option(field_type.clone())
        .unwrap_or_else(|| default_type_option_data_from_type(&field_type));
      (field, type_option_to_pb(type_option, &field_type))
    })
  }

  pub async fn create_field_with_type_option(
    &self,
    view_id: &str,
    field_type: &FieldType,
    type_option_data: Option<Vec<u8>>,
  ) -> (Field, Bytes) {
    let name = field_type.default_name();
    let type_option_data = match type_option_data {
      None => default_type_option_data_for_type(field_type),
      Some(type_option_data) => type_option_data_from_pb_or_default(type_option_data, field_type),
    };
    let (index, field) =
      self
        .database
        .lock()
        .create_default_field(view_id, name, field_type.into(), |field| {
          field
            .type_options
            .insert(field_type.to_string(), type_option_data.clone());
        });

    let _ = self
      .notify_did_insert_database_field(field.clone(), index)
      .await;

    (field, type_option_to_pb(type_option_data, field_type))
  }

  pub async fn move_field(
    &self,
    view_id: &str,
    field_id: &str,
    from: i32,
    to: i32,
  ) -> FlowyResult<()> {
    let (database_id, field) = {
      let database = self.database.lock();
      database.views.update_view(view_id, |view_update| {
        view_update.move_field_order(from as u32, to as u32);
      });
      let field = database.fields.get_field(field_id);
      let database_id = database.get_database_id();
      (database_id, field)
    };

    if let Some(field) = field {
      let delete_field = FieldIdPB::from(field_id);
      let insert_field = IndexFieldPB::from_field(field, to as usize);
      let notified_changeset = DatabaseFieldChangesetPB {
        view_id: database_id,
        inserted_fields: vec![insert_field],
        deleted_fields: vec![delete_field],
        updated_fields: vec![],
      };

      self.notify_did_update_database(notified_changeset).await?;
    }
    Ok(())
  }

  pub async fn get_rows(&self, view_id: &str) -> FlowyResult<Vec<Row>> {
    let rows = self.database.lock().get_rows_for_view(view_id);
    Ok(rows)
  }

  pub fn get_row(&self, row_id: RowId) -> Option<Row> {
    self.database.lock().get_row(row_id)
  }

  pub async fn delete_row(&self, row_id: RowId) {
    let row = self.database.lock().remove_row(row_id);
    if let Some(row) = row {
      tracing::trace!("Did delete row:{:?}", row);
      let _ = self
        .row_event_tx
        .send(DatabaseRowEvent::DeleteRow(row.id.into()));

      for view in self.database_views.editors().await {
        view.v_did_delete_row(&row).await;
      }
    }
  }

  pub async fn get_cell(&self, field_id: &str, row_id: RowId) -> CellPB {
    let field = self.database.lock().fields.get_field(field_id);
    let cell = self.database.lock().get_cell(field_id, row_id);
    match (field, cell) {
      (Some(field), Some(cell)) => {
        let field_type = FieldType::from(field.field_type);
        let cell_bytes = get_type_cell_protobuf(&cell, &field, Some(self.cell_cache.clone()));
        CellPB {
          field_id: field_id.to_string(),
          row_id: row_id.into(),
          data: cell_bytes.to_vec(),
          field_type: Some(field_type),
        }
      },
      _ => CellPB::empty(field_id, row_id.into()),
    }
  }

  pub async fn update_cell<T>(&self, row_id: RowId, field_id: &str, cell_changeset: T) -> Option<()>
  where
    T: ToCellChangeset,
  {
    let (field, old_row, cell) = {
      let database = self.database.lock();
      (
        database.fields.get_field(field_id)?,
        database.get_row(row_id),
        database.get_cell(field_id, row_id).map(|cell| cell.cell),
      )
    };

    let type_cell_data =
      apply_cell_data_changeset(cell_changeset, cell, &field, Some(self.cell_cache.clone()));
    self.database.lock().update_row(row_id, |row_update| {
      row_update.update_cells(|cell_update| {
        cell_update.insert(field_id, type_cell_data);
      });
    });

    let option_row = self.database.lock().get_row(row_id);
    if let Some(new_row) = option_row {
      let _ = self
        .row_event_tx
        .send(DatabaseRowEvent::UpdateRow(UpdatedRow {
          row: RowOrder::from(&new_row),
          field_ids: vec![field_id.to_string()],
        }));
      for view in self.database_views.editors().await {
        view.v_did_update_row(&old_row, &new_row).await;
      }
    }
    None
  }

  pub async fn create_select_option(
    &self,
    field_id: &str,
    option_name: String,
  ) -> Option<SelectOptionPB> {
    let field = self.database.lock().fields.get_field(field_id)?;
    let type_option = select_type_option_from_field(&field).ok()?;
    let select_option = type_option.create_option(&option_name);
    Some(SelectOptionPB::from(select_option))
  }

  pub async fn insert_select_options(
    &self,
    field_id: &str,
    row_id: RowId,
    options: Vec<SelectOptionPB>,
  ) -> Option<()> {
    let field = self.database.lock().fields.get_field(field_id)?;
    let mut type_option = select_type_option_from_field(&field).ok()?;
    let cell = SelectOptionCellChangeset {
      insert_option_ids: options.iter().map(|option| option.id.clone()).collect(),
      ..Default::default()
    };

    for option in options {
      type_option.insert_option(option.into());
    }
    self
      .database
      .lock()
      .fields
      .update_field(field_id, |update| {
        update.set_type_option(field.field_type, Some(type_option.to_type_option_data()));
      });

    self.update_cell(row_id, field_id, cell).await;
    None
  }

  pub async fn delete_select_options(
    &self,
    field_id: &str,
    row_id: RowId,
    options: Vec<SelectOptionPB>,
  ) -> Option<()> {
    let field = self.database.lock().fields.get_field(field_id)?;
    let mut type_option = select_type_option_from_field(&field).ok()?;
    let cell = SelectOptionCellChangeset {
      delete_option_ids: options.iter().map(|option| option.id.clone()).collect(),
      ..Default::default()
    };

    for option in options {
      type_option.delete_option(option.into());
    }
    self
      .database
      .lock()
      .fields
      .update_field(field_id, |update| {
        update.set_type_option(field.field_type, Some(type_option.to_type_option_data()));
      });

    self.update_cell(row_id, field_id, cell).await;
    None
  }

  pub async fn get_select_options(&self, row_id: RowId, field_id: &str) -> SelectOptionCellDataPB {
    let field = self.database.lock().fields.get_field(field_id);
    match field {
      None => SelectOptionCellDataPB::default(),
      Some(field) => {
        let row_cell = self.database.lock().get_cell(field_id, row_id);
        let ids = match row_cell {
          None => SelectOptionIds::new(),
          Some(row_cell) => SelectOptionIds::from(&row_cell.cell),
        };
        match select_type_option_from_field(&field) {
          Ok(type_option) => type_option.get_selected_options(ids).into(),
          Err(_) => SelectOptionCellDataPB::default(),
        }
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn load_groups(&self, view_id: &str) -> FlowyResult<RepeatedGroupPB> {
    let view = self.database_views.get_view_editor(view_id).await?;
    let groups = view.v_load_groups().await?;
    Ok(RepeatedGroupPB { items: groups })
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn get_group(&self, view_id: &str, group_id: &str) -> FlowyResult<GroupPB> {
    let view = self.database_views.get_view_editor(view_id).await?;
    let group = view.v_get_group(group_id).await?;
    Ok(group)
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group(
    &self,
    view_id: &str,
    from_group: &str,
    to_group: &str,
  ) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_move_group(from_group, to_group).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group_row(
    &self,
    view_id: &str,
    to_group: &str,
    from_row: RowId,
    to_row: Option<RowId>,
  ) -> FlowyResult<()> {
    let row = self.database.lock().get_row(from_row);
    match row {
      None => {
        tracing::warn!(
          "Move row between group failed, can not find the row:{}",
          from_row
        )
      },
      Some(row) => {
        let mut row_changeset = RowChangeset::new(row.id);
        let view = self.database_views.get_view_editor(view_id).await?;
        view
          .v_move_group_row(&row, &mut row_changeset, to_group, to_row)
          .await;

        tracing::trace!("Row data changed: {:?}", row_changeset);
        self.database.lock().update_row(row.id, |row| {
          row.set_cells(Cells::from(row_changeset.cell_by_field_id.clone()));
        });

        let cell_changesets = cell_changesets_from_cell_by_field_id(
          view_id,
          row_changeset.row_id,
          row_changeset.cell_by_field_id,
        );
        notify_did_update_cell(cell_changesets).await;
      },
    }

    Ok(())
  }

  pub async fn set_layout_setting(
    &self,
    view_id: &str,
    layout_ty: DatabaseLayout,
    layout_setting: LayoutSettingParams,
  ) {
    if let Ok(view) = self.database_views.get_view_editor(view_id).await {
      let _ = view.v_set_layout_settings(&layout_ty, layout_setting).await;
    }
  }

  pub async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: DatabaseLayout,
  ) -> Option<LayoutSettingParams> {
    let view = self.database_views.get_view_editor(view_id).await.ok()?;
    let layout_setting = view.v_get_layout_settings(&layout_ty).await;
    Some(layout_setting)
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn get_all_calendar_events(&self, view_id: &str) -> Vec<CalendarEventPB> {
    match self.database_views.get_view_editor(view_id).await {
      Ok(view) => view.v_get_all_calendar_events().await.unwrap_or_default(),
      Err(_) => {
        tracing::warn!("Can not find the view: {}", view_id);
        vec![]
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn get_calendar_event(&self, view_id: &str, row_id: RowId) -> Option<CalendarEventPB> {
    let view = self.database_views.get_view_editor(view_id).await.ok()?;
    view.v_get_calendar_event(row_id).await
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_insert_database_field(&self, field: Field, index: usize) -> FlowyResult<()> {
    let database_id = self.database.lock().get_database_id();
    let index_field = IndexFieldPB::from_field(field, index);
    let notified_changeset = DatabaseFieldChangesetPB::insert(&database_id, vec![index_field]);
    let _ = self.notify_did_update_database(notified_changeset).await;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_update_database_field(&self, field_id: &str) -> FlowyResult<()> {
    let (database_id, field) = {
      let database = self.database.lock();
      let database_id = database.get_database_id();
      let field = database.fields.get_field(field_id);
      (database_id, field)
    };

    if let Some(field) = field {
      let updated_field = FieldPB::from(field);
      let notified_changeset =
        DatabaseFieldChangesetPB::update(&database_id, vec![updated_field.clone()]);
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
    let views = self.database.lock().get_all_views_description();
    for view in views {
      send_notification(&view.id, DatabaseNotification::DidUpdateFields)
        .payload(changeset.clone())
        .send();
    }

    Ok(())
  }

  pub async fn get_database_view_setting(
    &self,
    view_id: &str,
  ) -> FlowyResult<DatabaseViewSettingPB> {
    let view = self
      .database
      .lock()
      .get_view(view_id)
      .ok_or(FlowyError::record_not_found().context("Can't find the database view"))?;
    Ok(database_view_setting_pb_from_view(view))
  }

  pub async fn get_database_data(&self) -> DatabasePB {
    let database = self.database.lock();
    get_database_data(&database)
  }
}

async fn notify_did_update_cell(changesets: Vec<CellChangesetPB>) {
  for changeset in changesets {
    let id = format!("{}:{}", changeset.row_id, changeset.field_id);
    send_notification(&id, DatabaseNotification::DidUpdateCell).send();
  }
}

fn cell_changesets_from_cell_by_field_id(
  view_id: &str,
  row_id: RowId,
  cell_by_field_id: HashMap<String, Cell>,
) -> Vec<CellChangesetPB> {
  let row_id = row_id.into();
  cell_by_field_id
    .into_iter()
    .map(|(field_id, _cell)| CellChangesetPB {
      view_id: view_id.to_string(),
      row_id,
      field_id,
      cell_changeset: "".to_string(),
    })
    .collect::<Vec<CellChangesetPB>>()
}

#[derive(Clone)]
pub struct MutexDatabase(Arc<Mutex<Arc<InnerDatabase>>>);

impl MutexDatabase {
  pub(crate) fn new(database: Arc<InnerDatabase>) -> Self {
    Self(Arc::new(Mutex::new(database)))
  }
}

impl Deref for MutexDatabase {
  type Target = Arc<Mutex<Arc<InnerDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for MutexDatabase {}

unsafe impl Send for MutexDatabase {}

struct DatabaseViewDataImpl {
  database: MutexDatabase,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl DatabaseViewData for DatabaseViewDataImpl {
  fn get_view_setting(&self, view_id: &str) -> Fut<Option<DatabaseView>> {
    let view = self.database.lock().get_view(view_id);
    to_fut(async move { view })
  }

  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    let fields = self.database.lock().get_fields(view_id, field_ids);
    to_fut(async move { fields.into_iter().map(Arc::new).collect() })
  }

  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_primary_field()
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn index_of_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<usize>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    to_fut(async move { index })
  }

  fn get_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<(usize, Arc<Row>)>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    let row = self.database.lock().get_row(row_id);
    to_fut(async move {
      match (index, row) {
        (Some(index), Some(row)) => Some((index, Arc::new(row))),
        _ => None,
      }
    })
  }

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>> {
    let rows = self.database.lock().get_rows_for_view(view_id);
    to_fut(async move { rows.into_iter().map(Arc::new).collect() })
  }

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>> {
    let cells = self.database.lock().get_cells_for_field(view_id, field_id);
    to_fut(async move { cells.into_iter().map(Arc::new).collect() })
  }

  fn get_cell_in_row(&self, field_id: &str, row_id: RowId) -> Fut<Option<Arc<RowCell>>> {
    let cell = self.database.lock().get_cell(field_id, row_id);
    to_fut(async move { cell.map(Arc::new) })
  }

  fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout {
    self
      .database
      .lock()
      .views
      .get_view_layout(view_id)
      .unwrap_or_default()
  }

  fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting> {
    self.database.lock().get_all_group_setting(view_id)
  }

  fn insert_group_setting(&self, view_id: &str, setting: GroupSetting) {
    self.database.lock().insert_group_setting(view_id, setting);
  }

  fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort> {
    self.database.lock().get_sort::<Sort>(view_id, sort_id)
  }

  fn insert_sort(&self, view_id: &str, sort: Sort) {
    self.database.lock().insert_sort(view_id, sort);
  }

  fn remove_sort(&self, view_id: &str, sort_id: &str) {
    self.database.lock().remove_sort(view_id, sort_id);
  }

  fn get_all_sorts(&self, view_id: &str) -> Vec<Sort> {
    self.database.lock().get_all_sorts::<Sort>(view_id)
  }

  fn remove_all_sorts(&self, view_id: &str) {
    self.database.lock().remove_all_sorts(view_id);
  }

  fn get_all_filters(&self, view_id: &str) -> Vec<Arc<Filter>> {
    self
      .database
      .lock()
      .get_all_filters(view_id)
      .into_iter()
      .map(Arc::new)
      .collect()
  }

  fn delete_filter(&self, view_id: &str, filter_id: &str) {
    self.database.lock().remove_filter(view_id, filter_id);
  }

  fn insert_filter(&self, view_id: &str, filter: Filter) {
    self.database.lock().insert_filter(view_id, filter);
  }

  fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter::<Filter>(view_id, filter_id)
  }

  fn get_filter_by_field_id(&self, view_id: &str, field_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter_by_field_id::<Filter>(view_id, field_id)
  }

  fn get_layout_setting(&self, view_id: &str, layout_ty: &DatabaseLayout) -> Option<LayoutSetting> {
    self
      .database
      .lock()
      .views
      .get_layout_setting(view_id, layout_ty)
  }

  fn insert_layout_setting(
    &self,
    _view_id: &str,
    _layout_setting: collab_database::views::LayoutSetting,
  ) {
    todo!()
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    _field: &Field,
    _field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    todo!()
  }
}
