use crate::entities::{FieldType, SelectOptionCellDataPB, SelectOptionFilterPB};
use crate::services::cell::CellDataChangeset;
use crate::services::field::{
  CellDataProtobufEncoder, SelectOptionCellChangeset, SelectTypeOptionSharedAction, TypeOption,
  TypeOptionCellDataCompare, TypeOptionCellDataFilter, default_order,
};
use crate::services::sort::SortCondition;

use collab_database::fields::TypeOptionData;
use collab_database::fields::select_type_option::{
  MultiSelectTypeOption, SelectOption, SelectOptionIds,
};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;

use std::cmp::Ordering;

impl TypeOption for MultiSelectTypeOption {
  type CellData = SelectOptionIds;
  type CellChangeset = SelectOptionCellChangeset;
  type CellProtobufType = SelectOptionCellDataPB;
  type CellFilter = SelectOptionFilterPB;
}

impl CellDataProtobufEncoder for MultiSelectTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.get_selected_options(cell_data).into()
  }
}

impl SelectTypeOptionSharedAction for MultiSelectTypeOption {
  fn number_of_max_options(&self) -> Option<usize> {
    None
  }

  fn to_type_option_data(&self) -> TypeOptionData {
    self.clone().into()
  }

  fn options(&self) -> &Vec<SelectOption> {
    &self.options
  }

  fn mut_options(&mut self) -> &mut Vec<SelectOption> {
    &mut self.options
  }
}

impl CellDataChangeset for MultiSelectTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let mut existing_ids: Vec<_> = cell
      .map(|cell| SelectOptionIds::from(&cell))
      .unwrap_or_default()
      .into_inner()
      .into_iter()
      .filter(|id| !changeset.delete_option_ids.contains(id))
      .collect();

    let valid_inserted_ids: Vec<_> = changeset
      .insert_option_ids
      .into_iter()
      .filter(|id| self.options.iter().any(|option| &option.id == id))
      .filter(|id| !existing_ids.iter().any(|existing_id| existing_id == id))
      .collect();

    existing_ids.extend(valid_inserted_ids);

    let select_option_ids: SelectOptionIds = existing_ids.into();

    Ok((
      select_option_ids.to_cell(FieldType::MultiSelect),
      select_option_ids,
    ))
  }
}

impl TypeOptionCellDataFilter for MultiSelectTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    let selected_options = self.get_selected_options(cell_data.clone()).select_options;
    filter.is_visible(&selected_options).unwrap_or(true)
  }
}

impl TypeOptionCellDataCompare for MultiSelectTypeOption {
  /// Orders two cell values to ensure non-empty cells are moved to the front and empty ones to the back.
  ///
  /// This function compares the two provided cell values (`left` and `right`) to determine their
  /// relative ordering:
  ///
  /// - If both cells are empty (`None`), they are considered equal.
  /// - If the left cell is empty and the right is not, the left cell is ordered to come after the right.
  /// - If the right cell is empty and the left is not, the left cell is ordered to come before the right.
  /// - If both cells are non-empty, they are ordered based on their names. If there is an additional sort condition,
  ///   this condition will further evaluate their order.
  ///
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match cell_data.len().cmp(&other_cell_data.len()) {
      Ordering::Equal => {
        for (left_id, right_id) in cell_data.iter().zip(other_cell_data.iter()) {
          let left = self.options.iter().find(|option| &option.id == left_id);
          let right = self.options.iter().find(|option| &option.id == right_id);
          let order = match (left, right) {
            (None, None) => Ordering::Equal,
            (None, Some(_)) => Ordering::Greater,
            (Some(_), None) => Ordering::Less,
            (Some(left_option), Some(right_option)) => {
              let name_order = left_option.name.cmp(&right_option.name);
              sort_condition.evaluate_order(name_order)
            },
          };

          if order.is_ne() {
            return order;
          }
        }
        default_order()
      },
      order => sort_condition.evaluate_order(order),
    }
  }
}
