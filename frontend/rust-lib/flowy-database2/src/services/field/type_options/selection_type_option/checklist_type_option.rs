use crate::entities::{ChecklistFilterPB, FieldType, SelectOptionCellDataPB};
use crate::services::cell::CellDataChangeset;
use crate::services::field::{
  SelectOption, SelectOptionCellChangeset, SelectOptionIds, SelectTypeOptionSharedAction,
  SelectedSelectOptions, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter,
};

use collab::core::lib0_any_ext::Lib0AnyMapExtension;
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

// Multiple select
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct ChecklistTypeOption {
  pub options: Vec<SelectOption>,
  pub disable_color: bool,
}

impl TypeOption for ChecklistTypeOption {
  type CellData = SelectOptionIds;
  type CellChangeset = SelectOptionCellChangeset;
  type CellProtobufType = SelectOptionCellDataPB;
  type CellFilter = ChecklistFilterPB;
}

impl From<TypeOptionData> for ChecklistTypeOption {
  fn from(data: TypeOptionData) -> Self {
    data
      .get_str_value("content")
      .map(|s| serde_json::from_str::<ChecklistTypeOption>(&s).unwrap_or_default())
      .unwrap_or_default()
  }
}

impl From<ChecklistTypeOption> for TypeOptionData {
  fn from(data: ChecklistTypeOption) -> Self {
    let content = serde_json::to_string(&data).unwrap_or_default();
    TypeOptionDataBuilder::new()
      .insert_str_value("content", content)
      .build()
  }
}

impl TypeOptionCellData for ChecklistTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.get_selected_options(cell_data).into()
  }

  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(SelectOptionIds::from(cell))
  }
}

impl SelectTypeOptionSharedAction for ChecklistTypeOption {
  fn number_of_max_options(&self) -> Option<usize> {
    None
  }

  fn options(&self) -> &Vec<SelectOption> {
    &self.options
  }

  fn mut_options(&mut self) -> &mut Vec<SelectOption> {
    &mut self.options
  }
}

impl CellDataChangeset for ChecklistTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let insert_option_ids = changeset
      .insert_option_ids
      .into_iter()
      .filter(|insert_option_id| {
        self
          .options
          .iter()
          .any(|option| &option.id == insert_option_id)
      })
      .collect::<Vec<String>>();

    let select_option_ids = match cell {
      None => SelectOptionIds::from(insert_option_ids),
      Some(cell) => {
        let mut select_ids = SelectOptionIds::from(&cell);
        for insert_option_id in insert_option_ids {
          if !select_ids.contains(&insert_option_id) {
            select_ids.push(insert_option_id);
          }
        }

        for delete_option_id in changeset.delete_option_ids {
          select_ids.retain(|id| id != &delete_option_id);
        }

        select_ids
      },
    };
    Ok((
      select_option_ids.to_cell_data(FieldType::Checklist),
      select_option_ids,
    ))
  }
}
impl TypeOptionCellDataFilter for ChecklistTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_check_list() {
      return true;
    }
    let selected_options =
      SelectedSelectOptions::from(self.get_selected_options(cell_data.clone()));
    filter.is_visible(&self.options, &selected_options)
  }
}

impl TypeOptionCellDataCompare for ChecklistTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    cell_data.len().cmp(&other_cell_data.len())
  }
}
