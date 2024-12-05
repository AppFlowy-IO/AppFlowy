use crate::entities::{TimeCellDataPB, TimeFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  CellDataProtobufEncoder, TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab_database::fields::date_type_option::TimeTypeOption;

use collab_database::rows::Cell;
use flowy_error::FlowyResult;

use collab_database::template::time_parse::TimeCellData;
use std::cmp::Ordering;

impl TypeOption for TimeTypeOption {
  type CellData = TimeCellData;
  type CellChangeset = TimeCellChangeset;
  type CellProtobufType = TimeCellDataPB;
  type CellFilter = TimeFilterPB;
}

impl CellDataProtobufEncoder for TimeTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    if let Some(time) = cell_data.0 {
      return TimeCellDataPB { time };
    }
    TimeCellDataPB {
      time: i64::default(),
    }
  }
}

impl TypeOptionTransform for TimeTypeOption {}

impl CellDataDecoder for TimeTypeOption {
  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    if let Some(time) = cell_data.0 {
      return time.to_string();
    }
    "".to_string()
  }
}

pub type TimeCellChangeset = String;

impl CellDataChangeset for TimeTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let str = changeset.trim().to_string();
    let cell_data = TimeCellData(str.parse::<i64>().ok());

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for TimeTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data.0)
  }
}

impl TypeOptionCellDataCompare for TimeTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    let order = cell_data.0.cmp(&other_cell_data.0);
    sort_condition.evaluate_order(order)
  }
}
