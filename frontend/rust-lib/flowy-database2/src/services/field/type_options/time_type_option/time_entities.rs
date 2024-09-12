use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::util::AnyMapExt;
use collab_database::database::timestamp;
use collab_database::rows::{new_cell_builder, Cell};
use flowy_error::FlowyError;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use strum_macros::EnumIter;

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct TimeCellData {
  pub time: Option<i64>,
  pub timer_start: Option<i64>,
  pub time_tracks: Vec<TimeTrack>,
}

impl TimeCellData {
  pub fn calculate_time(&self, time_type: TimeType) -> Option<i64> {
    let mut time_sum = self
      .time_tracks
      .clone()
      .into_iter()
      .fold(0, |total, time_track| {
        total + time_track.to_timestamp.unwrap_or(timestamp()) - time_track.from_timestamp
      });
    if time_type == TimeType::Timer {
      time_sum = self.timer_start.unwrap_or(0) - time_sum;
      if time_sum < 0 {
        time_sum = 0;
      }
    }
    Some(time_sum)
  }

  pub fn validate(&self) -> Option<FlowyError> {
    if self.time.unwrap_or(0) < 0 {
      return Some(FlowyError::internal().with_context("time can't get less than 0"));
    }
    if self.time.is_none() && !self.time_tracks.is_empty() {
      return Some(
        FlowyError::internal().with_context("time can't get removed when there are time tracks"),
      );
    }

    let to_none_time_tracks: Vec<TimeTrack> = self
      .time_tracks
      .clone()
      .into_iter()
      .filter(|tt| tt.to_timestamp.is_none())
      .collect();
    match to_none_time_tracks.len().cmp(&1) {
      Ordering::Greater => {
        return Some(
          FlowyError::internal()
            .with_context("time tracks can't contain two time track with none 'to_timestamp'"),
        )
      },
      Ordering::Equal => {
        let none_tt = &to_none_time_tracks[0];
        if self
          .time_tracks
          .iter()
          .any(|tt1| tt1.id != none_tt.id && tt1.from_timestamp > none_tt.from_timestamp)
        {
          return Some(FlowyError::internal().with_context(
            "cant add a time track which starts after the time track that is currently tracking",
          ));
        }
      },
      Ordering::Less => (),
    };

    if self.time_tracks.iter().any(|tt1| {
      self.time_tracks.iter().any(|tt2| {
        tt1.id != tt2.id
          && tt2.from_timestamp >= tt1.from_timestamp
          && tt2.from_timestamp <= tt1.to_timestamp.unwrap_or(timestamp())
      })
    }) {
      return Some(FlowyError::internal().with_context("time tracks can't have common periods"));
    }

    None
  }
}

impl ToString for TimeCellData {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl TypeOptionCellData for TimeCellData {
  fn is_cell_empty(&self) -> bool {
    self.time.is_none()
  }
}

const TIME_TRACKS: &str = "time_tracks";
const TIMER_START: &str = "timer_start";

impl From<&Cell> for TimeCellData {
  fn from(cell: &Cell) -> Self {
    let time = cell
      .get_as::<String>(CELL_DATA)
      .and_then(|data| data.parse::<i64>().ok());
    let timer_start = cell
      .get_as::<String>(TIMER_START)
      .and_then(|data| data.parse::<i64>().ok());
    let time_tracks = cell
      .get_as::<String>(TIME_TRACKS)
      .map(|data| serde_json::from_str::<Vec<TimeTrack>>(&data).unwrap_or_default())
      .unwrap_or_default();
    Self {
      time,
      timer_start,
      time_tracks,
    }
  }
}

impl From<&TimeCellData> for Cell {
  fn from(cell_data: &TimeCellData) -> Self {
    let time = match cell_data.time {
      Some(time) => time.to_string(),
      None => "".to_string(),
    };
    let timer_start = match cell_data.timer_start {
      Some(timer_start) => timer_start.to_string(),
      None => "".to_string(),
    };

    let mut cell = new_cell_builder(FieldType::Time);
    cell.insert(CELL_DATA.into(), time.into());
    cell.insert(TIMER_START.into(), timer_start.into());
    cell.insert(
      TIME_TRACKS.into(),
      serde_json::to_string(&cell_data.time_tracks)
        .unwrap_or_default()
        .into(),
    );
    cell
  }
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct TimeTrack {
  pub id: String,
  pub from_timestamp: i64,
  pub to_timestamp: Option<i64>,
}

impl TimeTrack {
  pub fn new(from_timestamp: i64, to_timestamp: Option<i64>) -> Self {
    Self {
      id: nanoid!(4),
      from_timestamp,
      to_timestamp,
    }
  }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, EnumIter, Serialize, Deserialize, Default)]
pub enum TimeType {
  #[default]
  Time = 0,
  Stopwatch = 1,
  Timer = 2,
}

impl TimeType {
  pub fn value(&self) -> i64 {
    *self as i64
  }
}

impl From<i64> for TimeType {
  fn from(value: i64) -> Self {
    match value {
      0 => TimeType::Time,
      1 => TimeType::Stopwatch,
      2 => TimeType::Timer,
      _ => TimeType::Time,
    }
  }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, EnumIter, Serialize, Deserialize, Default)]
pub enum TimePrecision {
  #[default]
  Minutes = 0,
  Seconds = 1,
}

impl TimePrecision {
  pub fn value(&self) -> i64 {
    *self as i64
  }
}

impl From<i64> for TimePrecision {
  fn from(value: i64) -> Self {
    match value {
      0 => TimePrecision::Minutes,
      1 => TimePrecision::Seconds,
      _ => TimePrecision::Minutes,
    }
  }
}

#[derive(Debug, Clone, Default)]
pub struct TimeCellChangeset {
  pub time: Option<i64>,
  pub timer_start: Option<i64>,
  pub delete_time_tracking_ids: Vec<String>,
  pub add_time_trackings: Vec<TimeTrack>,
  pub update_time_trackings: Vec<TimeTrack>,
}
