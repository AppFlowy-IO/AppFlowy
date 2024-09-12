use crate::entities::{TimeCellDataPB, TimeFilterPB, TimeTrackPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TimeCellChangeset, TimeCellData, TimePrecision, TimeTrack, TimeType, TypeOption,
  TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct TimeTypeOption {
  pub time_type: TimeType,
  pub precision: TimePrecision,
}

impl TypeOption for TimeTypeOption {
  type CellData = TimeCellData;
  type CellChangeset = TimeCellChangeset;
  type CellProtobufType = TimeCellDataPB;
  type CellFilter = TimeFilterPB;
}

const TIME_TYPE: &str = "time_type";
const PRECISION: &str = "precision";

impl From<TypeOptionData> for TimeTypeOption {
  fn from(data: TypeOptionData) -> Self {
    Self {
      time_type: data
        .get_as::<i64>(TIME_TYPE)
        .map(TimeType::from)
        .unwrap_or_default(),
      precision: data
        .get_as::<i64>(PRECISION)
        .map(TimePrecision::from)
        .unwrap_or_default(),
    }
  }
}

impl From<TimeTypeOption> for TypeOptionData {
  fn from(data: TimeTypeOption) -> Self {
    TypeOptionDataBuilder::from([
      (TIME_TYPE.into(), Any::BigInt(data.time_type.value())),
      (PRECISION.into(), Any::BigInt(data.precision.value())),
    ])
  }
}

impl TypeOptionCellDataSerde for TimeTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let mut cell_data_pb = TimeCellDataPB::default();
    if self.time_type == TimeType::Timer {
      cell_data_pb.timer_start = cell_data.timer_start.unwrap_or_default();
    }

    match self.time_type {
      TimeType::Time => {
        cell_data_pb.time = cell_data.time.unwrap_or_default();
      },
      TimeType::Timer | TimeType::Stopwatch => {
        cell_data_pb.time = cell_data.calculate_time(self.time_type).unwrap_or_default();
        cell_data_pb.time_tracks = cell_data
          .time_tracks
          .into_iter()
          .map(TimeTrackPB::from)
          .collect();
      },
    };

    if self.precision == TimePrecision::Minutes {
      cell_data_pb.time /= 60;
      cell_data_pb.timer_start /= 60;
    }

    cell_data_pb
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TimeCellData::from(cell))
  }
}

impl TimeTypeOption {
  pub fn new() -> Self {
    Self::default()
  }
}

impl TypeOptionTransform for TimeTypeOption {}

impl CellDataDecoder for TimeTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    if let Some(time) = cell_data.time {
      return time.to_string();
    }
    "".to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    let time_cell_data = self.parse_cell(cell).ok()?;
    time_cell_data.time.map(|time| time as f64)
  }
}

impl CellDataChangeset for TimeTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let mut cell_data = if let Some(cell) = cell {
      TimeCellData::from(&cell)
    } else {
      TimeCellData::default()
    };

    if self.time_type == TimeType::Timer {
      cell_data.timer_start = if changeset.timer_start.is_some() {
        changeset.timer_start
      } else {
        cell_data.timer_start
      };
    }

    match self.time_type {
      TimeType::Time => {
        cell_data.time = changeset.time;
      },
      TimeType::Stopwatch | TimeType::Timer => {
        apply_time_track_changeset(&mut cell_data.time_tracks, changeset.clone());
        cell_data.time = cell_data.calculate_time(self.time_type);
      },
    };

    if let Some(err) = cell_data.validate() {
      return Err(err);
    }

    Ok((Cell::from(&cell_data), cell_data))
  }
}

fn apply_time_track_changeset(time_tracks: &mut Vec<TimeTrack>, changeset: TimeCellChangeset) {
  time_tracks.retain(|time_track| !changeset.delete_time_tracking_ids.contains(&time_track.id));

  changeset
    .add_time_trackings
    .into_iter()
    .for_each(|time_track| {
      time_tracks.push(TimeTrack::new(
        time_track.from_timestamp,
        time_track.to_timestamp,
      ))
    });

  changeset
    .update_time_trackings
    .into_iter()
    .for_each(|updated_time_track| {
      if let Some(time_track) = time_tracks
        .iter_mut()
        .find(|time_track| time_track.id == updated_time_track.id)
      {
        time_track.from_timestamp = updated_time_track.from_timestamp;
        time_track.to_timestamp = updated_time_track.to_timestamp;
      }
    });
}

impl TypeOptionCellDataFilter for TimeTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data.time)
  }
}

impl TypeOptionCellDataCompare for TimeTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    let order = cell_data.time.cmp(&other_cell_data.time);
    sort_condition.evaluate_order(order)
  }
}
