use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::RowId;

use flowy_error::FlowyResult;
use lib_infra::future::{to_fut, Fut};

use crate::entities::FieldType;
use crate::services::database_view::DatabaseViewData;
use crate::services::field::RowSingleCellData;
use crate::services::group::{
  find_new_grouping_field, make_group_controller, GroupController, GroupSetting,
  GroupSettingReader, GroupSettingWriter,
};

pub async fn new_group_controller_with_field(
  view_id: String,
  delegate: Arc<dyn DatabaseViewData>,
  grouping_field: Arc<Field>,
) -> FlowyResult<Box<dyn GroupController>> {
  let setting_reader = GroupSettingReaderImpl(delegate.clone());
  let rows = delegate.get_rows(&view_id).await;
  let setting_writer = GroupSettingWriterImpl(delegate.clone());
  make_group_controller(
    view_id,
    grouping_field,
    rows,
    setting_reader,
    setting_writer,
  )
  .await
}

pub async fn new_group_controller(
  view_id: String,
  delegate: Arc<dyn DatabaseViewData>,
) -> FlowyResult<Box<dyn GroupController>> {
  let setting_reader = GroupSettingReaderImpl(delegate.clone());
  let setting_writer = GroupSettingWriterImpl(delegate.clone());

  let fields = delegate.get_fields(&view_id, None).await;
  let rows = delegate.get_rows(&view_id).await;
  let layout = delegate.get_layout_for_view(&view_id);

  // Read the grouping field or find a new grouping field
  let grouping_field = setting_reader
    .get_group_setting(&view_id)
    .await
    .and_then(|setting| {
      fields
        .iter()
        .find(|field| field.id == setting.field_id)
        .cloned()
    })
    .unwrap_or_else(|| find_new_grouping_field(&fields, &layout).unwrap());

  make_group_controller(
    view_id,
    grouping_field,
    rows,
    setting_reader,
    setting_writer,
  )
  .await
}

pub(crate) struct GroupSettingReaderImpl(pub Arc<dyn DatabaseViewData>);

impl GroupSettingReader for GroupSettingReaderImpl {
  fn get_group_setting(&self, view_id: &str) -> Fut<Option<Arc<GroupSetting>>> {
    let mut settings = self.0.get_group_setting(view_id);
    to_fut(async move {
      if settings.is_empty() {
        None
      } else {
        Some(Arc::new(settings.remove(0)))
      }
    })
  }

  fn get_configuration_cells(&self, view_id: &str, field_id: &str) -> Fut<Vec<RowSingleCellData>> {
    let field_id = field_id.to_owned();
    let view_id = view_id.to_owned();
    let delegate = self.0.clone();
    to_fut(async move { get_cells_for_field(delegate, &view_id, &field_id).await })
  }
}

pub(crate) async fn get_cell_for_row(
  delegate: Arc<dyn DatabaseViewData>,
  field_id: &str,
  row_id: &RowId,
) -> Option<RowSingleCellData> {
  let field = delegate.get_field(field_id).await?;
  let cell = delegate.get_cell_in_row(field_id, &row_id).await?;
  let field_type = FieldType::from(field.field_type);

  if let Some(handler) = delegate.get_type_option_cell_handler(&field, &field_type) {
    return match handler.get_cell_data(&cell, &field_type, &field) {
      Ok(cell_data) => Some(RowSingleCellData {
        row_id: cell.row_id.clone(),
        field_id: field.id.clone(),
        field_type: field_type.clone(),
        cell_data,
      }),
      Err(_) => None,
    };
  }
  None
}

// Returns the list of cells corresponding to the given field.
pub(crate) async fn get_cells_for_field(
  delegate: Arc<dyn DatabaseViewData>,
  view_id: &str,
  field_id: &str,
) -> Vec<RowSingleCellData> {
  if let Some(field) = delegate.get_field(field_id).await {
    let field_type = FieldType::from(field.field_type);
    if let Some(handler) = delegate.get_type_option_cell_handler(&field, &field_type) {
      let cells = delegate.get_cells_for_field(view_id, field_id).await;
      return cells
        .iter()
        .flat_map(
          |cell| match handler.get_cell_data(cell, &field_type, &field) {
            Ok(cell_data) => Some(RowSingleCellData {
              row_id: cell.row_id.clone(),
              field_id: field.id.clone(),
              field_type: field_type.clone(),
              cell_data,
            }),
            Err(_) => None,
          },
        )
        .collect();
    }
  }

  vec![]
}

struct GroupSettingWriterImpl(Arc<dyn DatabaseViewData>);

impl GroupSettingWriter for GroupSettingWriterImpl {
  fn save_configuration(&self, view_id: &str, group_setting: GroupSetting) -> Fut<FlowyResult<()>> {
    self.0.insert_group_setting(view_id, group_setting);
    to_fut(async move { Ok(()) })
  }
}
