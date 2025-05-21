use crate::entities::{FieldType, SelectOptionCellDataPB, SelectOptionFilterPB};
use crate::services::cell::CellDataChangeset;
use crate::services::field::{
  CellDataProtobufEncoder, TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  default_order,
};
use crate::services::field::{SelectOptionCellChangeset, SelectTypeOptionSharedAction};
use crate::services::sort::SortCondition;

use collab_database::fields::TypeOptionData;
use collab_database::fields::select_type_option::{
  SelectOption, SelectOptionIds, SingleSelectTypeOption,
};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;

use std::cmp::Ordering;

// Single select

impl TypeOption for SingleSelectTypeOption {
  type CellData = SelectOptionIds;
  type CellChangeset = SelectOptionCellChangeset;
  type CellProtobufType = SelectOptionCellDataPB;
  type CellFilter = SelectOptionFilterPB;
}

impl CellDataProtobufEncoder for SingleSelectTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.get_selected_options(cell_data).into()
  }
}

impl SelectTypeOptionSharedAction for SingleSelectTypeOption {
  fn number_of_max_options(&self) -> Option<usize> {
    Some(1)
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

impl CellDataChangeset for SingleSelectTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let valid_inserted_ids = changeset
      .insert_option_ids
      .into_iter()
      .filter(|id| self.options.iter().any(|option| &option.id == id));

    let existing_ids = cell
      .map(|cell| SelectOptionIds::from(&cell))
      .unwrap_or_default()
      .into_inner()
      .into_iter()
      .filter(|id| !changeset.delete_option_ids.contains(id));

    let select_option_ids: SelectOptionIds = valid_inserted_ids
      .chain(existing_ids)
      .take(1)
      .collect::<Vec<_>>()
      .into();

    Ok((
      select_option_ids.to_cell(FieldType::SingleSelect),
      select_option_ids,
    ))
  }
}

impl TypeOptionCellDataFilter for SingleSelectTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    let selected_options = self.get_selected_options(cell_data.clone()).select_options;
    filter.is_visible(&selected_options).unwrap_or(true)
  }
}

impl TypeOptionCellDataCompare for SingleSelectTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (
      cell_data
        .first()
        .and_then(|id| self.options.iter().find(|option| &option.id == id)),
      other_cell_data
        .first()
        .and_then(|id| self.options.iter().find(|option| &option.id == id)),
    ) {
      (Some(left), Some(right)) => {
        let order = left.name.cmp(&right.name);
        sort_condition.evaluate_order(order)
      },
      (Some(_), None) => Ordering::Less,
      (None, Some(_)) => Ordering::Greater,
      (None, None) => default_order(),
    }
  }
}
