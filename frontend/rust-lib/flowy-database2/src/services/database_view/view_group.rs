use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{RowDetail, RowId};

use flowy_error::FlowyResult;
use lib_infra::future::{to_fut, Fut};

use crate::entities::FieldType;
use crate::services::database_view::DatabaseViewOperation;
use crate::services::field::RowSingleCellData;
use crate::services::filter::FilterController;
use crate::services::group::{
  make_group_controller, GroupContextDelegate, GroupController, GroupControllerDelegate,
  GroupSetting,
};

pub async fn new_group_controller(
  view_id: String,
  delegate: Arc<dyn DatabaseViewOperation>,
  filter_controller: Arc<FilterController>,
  grouping_field: Option<Field>,
) -> FlowyResult<Option<Box<dyn GroupController>>> {
  if !delegate.get_layout_for_view(&view_id).is_board() {
    return Ok(None);
  }

  let controller_delegate = GroupControllerDelegateImpl {
    delegate: delegate.clone(),
    filter_controller: filter_controller.clone(),
  };

  let grouping_field = match grouping_field {
    Some(field) => Some(field),
    None => {
      let group_setting = controller_delegate.get_group_setting(&view_id).await;

      let fields = delegate.get_fields(&view_id, None).await;

      group_setting
        .and_then(|setting| {
          fields
            .iter()
            .find(|field| field.id == setting.field_id)
            .cloned()
        })
        .or_else(|| find_suitable_grouping_field(&fields))
    },
  };

  let controller = match grouping_field {
    Some(field) => Some(make_group_controller(&view_id, field, controller_delegate).await?),
    None => None,
  };

  Ok(controller)
}

pub(crate) struct GroupControllerDelegateImpl {
  delegate: Arc<dyn DatabaseViewOperation>,
  filter_controller: Arc<FilterController>,
}

impl GroupContextDelegate for GroupControllerDelegateImpl {
  fn get_group_setting(&self, view_id: &str) -> Fut<Option<Arc<GroupSetting>>> {
    let mut settings = self.delegate.get_group_setting(view_id);
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
    let delegate = self.delegate.clone();
    to_fut(async move { get_cells_for_field(delegate, &view_id, &field_id).await })
  }

  fn save_configuration(&self, view_id: &str, group_setting: GroupSetting) -> Fut<FlowyResult<()>> {
    self.delegate.insert_group_setting(view_id, group_setting);
    to_fut(async move { Ok(()) })
  }
}

impl GroupControllerDelegate for GroupControllerDelegateImpl {
  fn get_field(&self, field_id: &str) -> Option<Field> {
    self.delegate.get_field(field_id)
  }

  fn get_all_rows(&self, view_id: &str) -> Fut<Vec<Arc<RowDetail>>> {
    let view_id = view_id.to_string();
    let delegate = self.delegate.clone();
    let filter_controller = self.filter_controller.clone();
    to_fut(async move {
      let mut row_details = delegate.get_rows(&view_id).await;
      filter_controller.filter_rows(&mut row_details).await;
      row_details
    })
  }
}

pub(crate) async fn get_cell_for_row(
  delegate: Arc<dyn DatabaseViewOperation>,
  field_id: &str,
  row_id: &RowId,
) -> Option<RowSingleCellData> {
  let field = delegate.get_field(field_id)?;
  let row_cell = delegate.get_cell_in_row(field_id, row_id).await;
  let field_type = FieldType::from(field.field_type);
  let handler = delegate.get_type_option_cell_handler(&field)?;

  let cell_data = match &row_cell.cell {
    None => None,
    Some(cell) => handler.handle_get_boxed_cell_data(cell, &field),
  };
  Some(RowSingleCellData {
    row_id: row_cell.row_id.clone(),
    field_id: field.id.clone(),
    field_type,
    cell_data,
  })
}

// Returns the list of cells corresponding to the given field.
pub(crate) async fn get_cells_for_field(
  delegate: Arc<dyn DatabaseViewOperation>,
  view_id: &str,
  field_id: &str,
) -> Vec<RowSingleCellData> {
  if let Some(field) = delegate.get_field(field_id) {
    let field_type = FieldType::from(field.field_type);
    if let Some(handler) = delegate.get_type_option_cell_handler(&field) {
      let cells = delegate.get_cells_for_field(view_id, field_id).await;
      return cells
        .iter()
        .map(|row_cell| {
          let cell_data = match &row_cell.cell {
            None => None,
            Some(cell) => handler.handle_get_boxed_cell_data(cell, &field),
          };
          RowSingleCellData {
            row_id: row_cell.row_id.clone(),
            field_id: field.id.clone(),
            field_type,
            cell_data,
          }
        })
        .collect();
    }
  }

  vec![]
}

fn find_suitable_grouping_field(fields: &[Field]) -> Option<Field> {
  let groupable_field = fields
    .iter()
    .find(|field| FieldType::from(field.field_type).can_be_group());

  if let Some(field) = groupable_field {
    Some(field.clone())
  } else {
    fields.iter().find(|field| field.is_primary).cloned()
  }
}
