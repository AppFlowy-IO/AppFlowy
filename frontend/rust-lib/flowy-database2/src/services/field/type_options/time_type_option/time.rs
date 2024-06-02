use crate::entities::{TimeCellDataPB, TimeFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TimeCellData, TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct TimeTypeOption;

impl TypeOption for TimeTypeOption {
  type CellData = TimeCellData;
  type CellChangeset = TimeCellChangeset;
  type CellProtobufType = TimeCellDataPB;
  type CellFilter = TimeFilterPB;
}

impl From<TypeOptionData> for TimeTypeOption {
  fn from(_data: TypeOptionData) -> Self {
    Self
  }
}

impl From<TimeTypeOption> for TypeOptionData {
  fn from(_data: TimeTypeOption) -> Self {
    TypeOptionDataBuilder::new().build()
  }
}

impl TypeOptionCellDataSerde for TimeTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    if let Some(minutes) = cell_data.0 {
      return TimeCellDataPB {
        minutes,
        time: TimeTypeOption::format_cell_data(minutes),
      };
    }
    TimeCellDataPB {
      minutes: i64::default(),
      time: "".to_string(),
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TimeCellData::from(cell))
  }
}

impl TimeTypeOption {
  pub fn new() -> Self {
    Self
  }

  pub(crate) fn format_cell_data(minutes: i64) -> String {
    if minutes >= 60 {
      if minutes % 60 == 0 {
        return format!("{}h", minutes / 60);
      }
      return format!("{}h {}m", minutes / 60, minutes % 60);
    } else if minutes >= 0 {
      return format!("{}m", minutes);
    }
    "".to_string()
  }
}

impl TypeOptionTransform for TimeTypeOption {}

impl CellDataDecoder for TimeTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    if let Some(minutes) = cell_data.0 {
      return TimeTypeOption::format_cell_data(minutes);
    }
    "".to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    let time_cell_data = self.parse_cell(cell).ok()?;
    Some(time_cell_data.0.unwrap() as f64)
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

#[cfg(test)]
mod tests {
  use crate::services::field::TimeTypeOption;

  #[test]
  fn format_cell_data_test() {
    struct TimeFormatTest<'a> {
      minutes: i64,
      exp: &'a str,
    }

    let tests = vec![
      TimeFormatTest {
        minutes: 5,
        exp: "5m",
      },
      TimeFormatTest {
        minutes: 75,
        exp: "1h 15m",
      },
      TimeFormatTest {
        minutes: 120,
        exp: "2h",
      },
      TimeFormatTest {
        minutes: 0,
        exp: "0m",
      },
      TimeFormatTest {
        minutes: -50,
        exp: "",
      },
    ];
    for test in tests {
      let res = TimeTypeOption::format_cell_data(test.minutes);
      assert_eq!(res, test.exp.to_string());
    }
  }
}
