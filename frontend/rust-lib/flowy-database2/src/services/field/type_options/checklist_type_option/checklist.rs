use crate::entities::{ChecklistFilterPB, FieldType, SelectOptionCellDataPB, SelectOptionPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::checklist_type_option::{ChecklistCellChangeset, ChecklistCellData};
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  SELECTION_IDS_SEPARATOR,
};
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use std::cmp::Ordering;

#[derive(Debug, Clone, Default)]
pub struct ChecklistTypeOption2;

impl TypeOption for ChecklistTypeOption2 {
  type CellData = ChecklistCellData;
  type CellChangeset = ChecklistCellChangeset;
  type CellProtobufType = SelectOptionCellDataPB;
  type CellFilter = ChecklistFilterPB;
}

impl From<TypeOptionData> for ChecklistTypeOption2 {
  fn from(_data: TypeOptionData) -> Self {
    Self
  }
}

impl From<ChecklistTypeOption2> for TypeOptionData {
  fn from(_data: ChecklistTypeOption2) -> Self {
    TypeOptionDataBuilder::new().build()
  }
}

impl TypeOptionCellData for ChecklistTypeOption2 {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let select_options = cell_data
      .options
      .iter()
      .filter(|option| cell_data.selected_option_ids.contains(&option.id))
      .map(|option| SelectOptionPB::from(option.clone()))
      .collect();

    let options = cell_data
      .options
      .into_iter()
      .map(SelectOptionPB::from)
      .collect();

    SelectOptionCellDataPB {
      options,
      select_options,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(ChecklistCellData::from(cell))
  }
}

impl CellDataChangeset for ChecklistTypeOption2 {
  fn apply_changeset(
    &self,
    _changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    todo!()
  }
}

impl CellDataDecoder for ChecklistTypeOption2 {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if !decoded_field_type.is_checklist() {
      return Ok(Default::default());
    }

    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data
      .selected_options()
      .into_iter()
      .map(|option| option.name)
      .collect::<Vec<_>>()
      .join(SELECTION_IDS_SEPARATOR)
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    let cell_data = self.parse_cell(cell).unwrap_or_default();
    self.stringify_cell_data(cell_data)
  }
}

impl TypeOptionCellDataFilter for ChecklistTypeOption2 {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_checklist() {
      return true;
    }
    let selected_options = cell_data.selected_options();
    filter.is_visible(&cell_data.options, &selected_options)
  }
}

impl TypeOptionCellDataCompare for ChecklistTypeOption2 {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    let left = cell_data.percentage_complete();
    let right = other_cell_data.percentage_complete();
    if left > right {
      Ordering::Greater
    } else if left < right {
      Ordering::Less
    } else {
      Ordering::Equal
    }
  }
}
