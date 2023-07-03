use std::cmp::Ordering;
use std::str::FromStr;

use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use serde::{Deserialize, Serialize};

use flowy_error::FlowyResult;

use crate::entities::{CheckboxFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, CheckboxCellData, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform,
};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CheckboxTypeOption {
  pub is_selected: bool,
}

impl TypeOption for CheckboxTypeOption {
  type CellData = CheckboxCellData;
  type CellChangeset = CheckboxCellChangeset;
  type CellProtobufType = CheckboxCellData;
  type CellFilter = CheckboxFilterPB;
}

impl TypeOptionTransform for CheckboxTypeOption {
  fn transformable(&self) -> bool {
    true
  }

  fn transform_type_option(
    &mut self,
    _old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
  ) {
  }

  fn transform_type_option_cell(
    &self,
    cell: &Cell,
    transformed_field_type: &FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    if transformed_field_type.is_text() {
      Some(CheckboxCellData::from(cell))
    } else {
      None
    }
  }
}

impl From<TypeOptionData> for CheckboxTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let is_selected = data.get_bool_value("is_selected").unwrap_or(false);
    CheckboxTypeOption { is_selected }
  }
}

impl From<CheckboxTypeOption> for TypeOptionData {
  fn from(data: CheckboxTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_bool_value("is_selected", data.is_selected)
      .build()
  }
}

impl TypeOptionCellData for CheckboxTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(CheckboxCellData::from(cell))
  }
}

impl CellDataDecoder for CheckboxTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if !decoded_field_type.is_checkbox() {
      return Ok(Default::default());
    }
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.to_string()
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    Self::CellData::from(cell).to_string()
  }
}

pub type CheckboxCellChangeset = String;

impl CellDataChangeset for CheckboxTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let checkbox_cell_data = CheckboxCellData::from_str(&changeset)?;
    Ok((checkbox_cell_data.clone().into(), checkbox_cell_data))
  }
}

impl TypeOptionCellDataFilter for CheckboxTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_checkbox() {
      return true;
    }
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for CheckboxTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    match (cell_data.is_check(), other_cell_data.is_check()) {
      (true, true) => Ordering::Equal,
      (true, false) => Ordering::Greater,
      (false, true) => Ordering::Less,
      (false, false) => default_order(),
    }
  }
}
