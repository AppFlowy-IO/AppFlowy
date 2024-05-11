use crate::services::field::TimerTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimerTypeOptionPB {
  #[pb(index = 1)]
  pub dummy: String,
}

impl From<TimerTypeOption> for TimerTypeOptionPB {
  fn from(_data: TimerTypeOption) -> Self {
    Self {
      dummy: "".to_string(),
    }
  }
}

impl From<TimerTypeOptionPB> for TimerTypeOption {
  fn from(_data: TimerTypeOptionPB) -> Self {
    Self
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimerCellDataPB {
  #[pb(index = 1)]
  pub timer: String,

  #[pb(index = 2)]
  pub minutes: i64,
}
