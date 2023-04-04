use crate::entities::{ChecklistFilterPB, FieldType, SelectOptionCellDataPB};
use crate::services::cell::{CellDataChangeset, FromCellString, TypeCellData};
use crate::services::field::{
  CheckboxTypeOption, SelectOption, SelectOptionCellChangeset, SelectOptionIds,
  SelectTypeOptionSharedAction, SelectedSelectOptions, TypeOption, TypeOptionCellData,
  TypeOptionCellDataCompare, TypeOptionCellDataFilter,
};

use collab_database::fields::TypeOptionData;
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
  fn from(_: TypeOptionData) -> Self {
    todo!()
  }
}

impl From<ChecklistTypeOption> for TypeOptionData {
  fn from(_: CheckboxTypeOption) -> Self {
    todo!()
  }
}

impl TypeOptionCellData for ChecklistTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.get_selected_options(cell_data).into()
  }

  fn decode_type_option_cell_str(
    &self,
    cell_str: String,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    SelectOptionIds::from_cell_str(&cell_str)
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
    type_cell_data: Option<TypeCellData>,
  ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
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

    let select_option_ids = match type_cell_data {
      None => SelectOptionIds::from(insert_option_ids),
      Some(type_cell_data) => {
        let mut select_ids: SelectOptionIds = type_cell_data.cell_str.into();
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
    Ok((select_option_ids.to_string(), select_option_ids))
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
