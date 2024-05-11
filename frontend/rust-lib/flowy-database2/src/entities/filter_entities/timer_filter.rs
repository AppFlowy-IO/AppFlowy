use flowy_derive::ProtoBuf;

use crate::entities::NumberFilterConditionPB;
use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TimerFilterPB {
  #[pb(index = 1)]
  pub condition: NumberFilterConditionPB,

  #[pb(index = 2)]
  pub content: String,
}

impl ParseFilterData for TimerFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    TimerFilterPB {
      condition: NumberFilterConditionPB::try_from(condition)
        .unwrap_or(NumberFilterConditionPB::Equal),
      content,
    }
  }
}
