use crate::services::field::SelectOptionIds;
use crate::services::filter::{Filter, FromFilterString};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionFilterPB {
  #[pb(index = 1)]
  pub condition: SelectOptionConditionPB,

  #[pb(index = 2)]
  pub option_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
pub enum SelectOptionConditionPB {
  #[default]
  OptionIs = 0,
  OptionIsNot = 1,
  OptionIsEmpty = 2,
  OptionIsNotEmpty = 3,
}

impl std::convert::From<SelectOptionConditionPB> for u32 {
  fn from(value: SelectOptionConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for SelectOptionConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(SelectOptionConditionPB::OptionIs),
      1 => Ok(SelectOptionConditionPB::OptionIsNot),
      2 => Ok(SelectOptionConditionPB::OptionIsEmpty),
      3 => Ok(SelectOptionConditionPB::OptionIsNotEmpty),
      _ => Err(ErrorCode::InvalidData),
    }
  }
}
impl FromFilterString for SelectOptionFilterPB {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized,
  {
    let ids = SelectOptionIds::from(filter.content.clone());
    SelectOptionFilterPB {
      condition: SelectOptionConditionPB::try_from(filter.condition as u8)
        .unwrap_or(SelectOptionConditionPB::OptionIs),
      option_ids: ids.into_inner(),
    }
  }
}

impl std::convert::From<&Filter> for SelectOptionFilterPB {
  fn from(filter: &Filter) -> Self {
    let ids = SelectOptionIds::from(filter.content.clone());
    SelectOptionFilterPB {
      condition: SelectOptionConditionPB::try_from(filter.condition as u8)
        .unwrap_or(SelectOptionConditionPB::OptionIs),
      option_ids: ids.into_inner(),
    }
  }
}
