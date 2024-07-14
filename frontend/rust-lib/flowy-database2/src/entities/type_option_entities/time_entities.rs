use crate::{
  entities::CellIdPB,
  services::field::{TimePrecision, TimeTrack, TimeType, TimeTypeOption},
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use strum_macros::EnumIter;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeTypeOptionPB {
  #[pb(index = 1)]
  pub time_type: TimeTypePB,

  #[pb(index = 2)]
  pub precision: TimePrecisionPB,
}

impl From<TimeTypeOption> for TimeTypeOptionPB {
  fn from(data: TimeTypeOption) -> Self {
    Self {
      time_type: data.time_type.into(),
      precision: data.precision.into(),
    }
  }
}

impl From<TimeTypeOptionPB> for TimeTypeOption {
  fn from(data: TimeTypeOptionPB) -> Self {
    Self {
      time_type: data.time_type.into(),
      precision: data.precision.into(),
    }
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeCellDataPB {
  #[pb(index = 1)]
  pub time: i64,

  #[pb(index = 2)]
  pub timer_start: i64,

  #[pb(index = 3)]
  pub time_tracks: Vec<TimeTrackPB>,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeTrackPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub from_timestamp: i64,

  #[pb(index = 3, one_of)]
  pub to_timestamp: Option<i64>,
}

impl From<TimeTrackPB> for TimeTrack {
  fn from(data: TimeTrackPB) -> Self {
    return Self {
      id: data.id,
      from_timestamp: data.from_timestamp,
      to_timestamp: data.to_timestamp,
    };
  }
}

impl From<TimeTrack> for TimeTrackPB {
  fn from(data: TimeTrack) -> Self {
    return Self {
      id: data.id,
      from_timestamp: data.from_timestamp,
      to_timestamp: data.to_timestamp,
    };
  }
}

#[derive(Clone, Debug, Copy, ProtoBuf_Enum, Default)]
pub enum TimeTypePB {
  #[default]
  PlainTime = 0,
  Stopwatch = 1,
  Timer = 2,
}

impl From<TimeTypePB> for TimeType {
  fn from(data: TimeTypePB) -> Self {
    match data {
      TimeTypePB::PlainTime => TimeType::Time,
      TimeTypePB::Stopwatch => TimeType::Stopwatch,
      TimeTypePB::Timer => TimeType::Timer,
    }
  }
}

impl From<TimeType> for TimeTypePB {
  fn from(data: TimeType) -> Self {
    match data {
      TimeType::Time => TimeTypePB::PlainTime,
      TimeType::Stopwatch => TimeTypePB::Stopwatch,
      TimeType::Timer => TimeTypePB::Timer,
    }
  }
}

#[derive(Clone, Copy, PartialEq, Eq, EnumIter, Debug, Hash, ProtoBuf_Enum, Default)]
pub enum TimePrecisionPB {
  #[default]
  Minutes = 0,
  Seconds = 1,
}

impl From<TimePrecisionPB> for TimePrecision {
  fn from(data: TimePrecisionPB) -> Self {
    match data {
      TimePrecisionPB::Minutes => TimePrecision::Minutes,
      TimePrecisionPB::Seconds => TimePrecision::Seconds,
    }
  }
}

impl From<TimePrecision> for TimePrecisionPB {
  fn from(data: TimePrecision) -> Self {
    match data {
      TimePrecision::Minutes => TimePrecisionPB::Minutes,
      TimePrecision::Seconds => TimePrecisionPB::Seconds,
    }
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeCellChangesetPB {
  #[pb(index = 1)]
  pub cell_id: CellIdPB,

  #[pb(index = 2, one_of)]
  pub time: Option<i64>,

  #[pb(index = 3, one_of)]
  pub timer_start: Option<i64>,

  #[pb(index = 4)]
  pub add_time_trackings: Vec<TimeTrackPB>,

  #[pb(index = 5)]
  pub delete_time_tracking_ids: Vec<String>,

  #[pb(index = 6)]
  pub update_time_trackings: Vec<TimeTrackPB>,
}
