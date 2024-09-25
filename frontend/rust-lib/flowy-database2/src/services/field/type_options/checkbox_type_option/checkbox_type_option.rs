use std::cmp::Ordering;
use std::str::FromStr;

use collab_database::fields::checkbox_type_option::CheckboxTypeOption;
use collab_database::fields::Field;
use collab_database::rows::Cell;

use flowy_error::FlowyResult;

use crate::entities::{CheckboxCellDataPB, CheckboxFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform,
};
use crate::services::sort::SortCondition;

impl TypeOption for CheckboxTypeOption {
  type CellData = CheckboxCellDataPB;
  type CellChangeset = CheckboxCellChangeset;
  type CellProtobufType = CheckboxCellDataPB;
  type CellFilter = CheckboxFilterPB;
}

impl TypeOptionTransform for CheckboxTypeOption {}

impl TypeOptionCellDataSerde for CheckboxTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(CheckboxCellDataPB::from(cell))
  }
}

impl CellDataDecoder for CheckboxTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    if from_field_type.is_text() {
      Some(CheckboxCellDataPB::from(cell))
    } else {
      None
    }
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    let cell_data = self.parse_cell(cell).ok()?;
    if cell_data.is_checked {
      Some(1.0)
    } else {
      Some(0.0)
    }
  }
}

pub type CheckboxCellChangeset = String;

impl CellDataChangeset for CheckboxTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let checkbox_cell_data = CheckboxCellDataPB::from_str(&changeset)?;
    Ok((checkbox_cell_data.clone().into(), checkbox_cell_data))
  }
}

impl TypeOptionCellDataFilter for CheckboxTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for CheckboxTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    let order = cell_data.is_checked.cmp(&other_cell_data.is_checked);
    sort_condition.evaluate_order(order)
  }

  /// Compares two cell data using a specified sort condition and accounts for uninitialized cells.
  ///
  /// This function checks if either `cell_data` or `other_cell_data` is checked (i.e., has the `is_check` property set).
  /// If the right cell is checked and the left cell isn't, the function will return `Ordering::Less`. Conversely, if the
  /// left cell is checked and the right one isn't, the function will return `Ordering::Greater`. In all other cases, it returns
  /// `Ordering::Equal`.
  fn apply_cmp_with_uninitialized(
    &self,
    cell_data: Option<&<Self as TypeOption>::CellData>,
    other_cell_data: Option<&<Self as TypeOption>::CellData>,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data, other_cell_data) {
      (None, Some(right_cell_data)) if right_cell_data.is_checked => {
        sort_condition.evaluate_order(Ordering::Less)
      },
      (Some(left_cell_data), None) if left_cell_data.is_checked => {
        sort_condition.evaluate_order(Ordering::Greater)
      },
      _ => Ordering::Equal,
    }
  }
}
