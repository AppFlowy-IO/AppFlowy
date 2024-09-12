use async_trait::async_trait;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};

use flowy_error::FlowyResult;

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
  if !delegate.get_layout_for_view(&view_id).await.is_board() {
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

#[async_trait]
impl GroupContextDelegate for GroupControllerDelegateImpl {
  async fn get_group_setting(&self, view_id: &str) -> Option<Arc<GroupSetting>> {
    let mut settings = self.delegate.get_group_setting(view_id).await;
    if settings.is_empty() {
      None
    } else {
      Some(Arc::new(settings.remove(0)))
    }
  }

  async fn get_configuration_cells(&self, view_id: &str, field_id: &str) -> Vec<RowSingleCellData> {
    let delegate = self.delegate.clone();
    get_cells_for_field(delegate, view_id, field_id).await
  }

  async fn save_configuration(
    &self,
    view_id: &str,
    group_setting: GroupSetting,
  ) -> FlowyResult<()> {
    self
      .delegate
      .insert_group_setting(view_id, group_setting)
      .await;
    Ok(())
  }
}

#[async_trait]
impl GroupControllerDelegate for GroupControllerDelegateImpl {
  async fn get_field(&self, field_id: &str) -> Option<Field> {
    self.delegate.get_field(field_id).await
  }

  async fn get_all_rows(&self, view_id: &str) -> Vec<Arc<Row>> {
    let row_orders = self.delegate.get_all_row_orders(view_id).await;
    let rows = self.delegate.get_all_rows(view_id, row_orders).await;
    let rows = self.filter_controller.filter_rows(rows).await;
    rows
  }
}

pub(crate) async fn get_cell_for_row(
  delegate: Arc<dyn DatabaseViewOperation>,
  field_id: &str,
  row_id: &RowId,
) -> Option<RowSingleCellData> {
  let field = delegate.get_field(field_id).await?;
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
  if let Some(field) = delegate.get_field(field_id).await {
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
