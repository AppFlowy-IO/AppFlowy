use crate::services::field::TimeTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeTypeOptionPB {
  #[pb(index = 1)]
  pub dummy: String,
}

impl From<TimeTypeOption> for TimeTypeOptionPB {
  fn from(_data: TimeTypeOption) -> Self {
    Self {
      dummy: "".to_string(),
    }
  }
}

impl From<TimeTypeOptionPB> for TimeTypeOption {
  fn from(_data: TimeTypeOptionPB) -> Self {
    Self
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimeCellDataPB {
  #[pb(index = 1)]
  pub time: String,

  #[pb(index = 2)]
  pub minutes: i64,
}
