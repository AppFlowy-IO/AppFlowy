use crate::entities::{TimerCellDataPB, TimerFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TimerCellData, TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct TimerTypeOption;

impl TypeOption for TimerTypeOption {
  type CellData = TimerCellData;
  type CellChangeset = TimerCellChangeset;
  type CellProtobufType = TimerCellDataPB;
  type CellFilter = TimerFilterPB;
}

impl From<TypeOptionData> for TimerTypeOption {
  fn from(_data: TypeOptionData) -> Self {
    Self
  }
}

impl From<TimerTypeOption> for TypeOptionData {
  fn from(_data: TimerTypeOption) -> Self {
    TypeOptionDataBuilder::new().build()
  }
}

impl TypeOptionCellDataSerde for TimerTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    if let Some(minutes) = cell_data.0 {
      return TimerCellDataPB {
        minutes,
        timer: TimerTypeOption::format_cell_data(minutes),
      };
    }
    TimerCellDataPB {
      minutes: i64::default(),
      timer: "".to_string(),
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TimerCellData::from(cell))
  }
}

impl TimerTypeOption {
  pub fn new() -> Self {
    Self::default()
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

impl TypeOptionTransform for TimerTypeOption {}

impl CellDataDecoder for TimerTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    let timer_cell_data = self.parse_cell(cell)?;
    Ok(TimerCellData::from(
      TimerTypeOption::format_cell_data(&timer_cell_data).to_string(),
    ))
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    if let Some(minutes) = cell_data.0 {
      return TimerTypeOption::format_cell_data(minutes);
    }
    "".to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    let timer_cell_data = self.parse_cell(cell).ok()?;
    timer_cell_data.0.parse::<f64>().ok()
  }
}

pub type TimerCellChangeset = String;

impl CellDataChangeset for TimerTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let str = changeset.trim().to_string();
    let cell_data = TimerCellData(str.parse::<i64>().ok());

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for TimerTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    match self.format_cell_data(cell_data) {
      Ok(cell_data) => filter.is_visible(&cell_data).unwrap_or(true),
      Err(_) => true,
    }
  }
}

impl TypeOptionCellDataCompare for TimerTypeOption {
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
  use crate::services::field::TimerTypeOption;

  #[test]
  fn format_cell_data_test() {
    struct TimerFormatTest<'a> {
      minutes: i64,
      exp: &'a str,
    }

    let tests = vec![
      TimerFormatTest {
        minutes: 5,
        exp: "5m",
      },
      TimerFormatTest {
        minutes: 75,
        exp: "1h 15m",
      },
      TimerFormatTest {
        minutes: 120,
        exp: "2h",
      },
      TimerFormatTest {
        minutes: 0,
        exp: "0m",
      },
      TimerFormatTest {
        minutes: -50,
        exp: "",
      },
    ];
    for test in tests {
      let res = TimerTypeOption::format_cell_data(test.minutes);
      assert_eq!(res, test.exp.to_string());
    }
  }
}
