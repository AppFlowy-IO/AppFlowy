use crate::entities::{DateFilterPB, TimestampCellDataPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, TimestampCellData, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab_database::fields::timestamp_type_option::TimestampTypeOption;
use collab_database::rows::Cell;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use std::cmp::Ordering;

impl TypeOption for TimestampTypeOption {
  type CellData = TimestampCellData;
  type CellChangeset = String;
  type CellProtobufType = TimestampCellDataPB;
  type CellFilter = DateFilterPB;
}

impl TypeOptionCellDataSerde for TimestampTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let timestamp = cell_data.timestamp;
    let date_time = self.stringify_cell_data(cell_data);

    TimestampCellDataPB {
      date_time,
      timestamp,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TimestampCellData::from(cell))
  }
}

impl TypeOptionTransform for TimestampTypeOption {}

impl CellDataDecoder for TimestampTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    let timestamp = cell_data.timestamp;
    let (date_string, time_string) = self.formatted_date_time_from_timestamp(&timestamp);
    if self.include_time {
      format!("{} {}", date_string, time_string)
    } else {
      date_string
    }
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

impl CellDataChangeset for TimestampTypeOption {
  fn apply_changeset(
    &self,
    _changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    Err(FlowyError::new(
      ErrorCode::FieldInvalidOperation,
      "Cells of this field type cannot be edited",
    ))
  }
}

impl TypeOptionCellDataFilter for TimestampTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter
      .is_timestamp_cell_data_visible(cell_data)
      .unwrap_or(true)
  }
}

impl TypeOptionCellDataCompare for TimestampTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data.timestamp, other_cell_data.timestamp) {
      (Some(left), Some(right)) => {
        let order = left.cmp(&right);
        sort_condition.evaluate_order(order)
      },
      (Some(_), None) => Ordering::Less,
      (None, Some(_)) => Ordering::Greater,
      (None, None) => default_order(),
    }
  }
}
