use crate::services::filter::{Filter, FromFilterString};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TextFilterPB {
  #[pb(index = 1)]
  pub condition: TextFilterConditionPB,

  #[pb(index = 2)]
  pub content: String,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
#[derive(Default)]
pub enum TextFilterConditionPB {
  #[default]
  Is = 0,
  IsNot = 1,
  Contains = 2,
  DoesNotContain = 3,
  StartsWith = 4,
  EndsWith = 5,
  TextIsEmpty = 6,
  TextIsNotEmpty = 7,
}

impl std::convert::From<TextFilterConditionPB> for u32 {
  fn from(value: TextFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for TextFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(TextFilterConditionPB::Is),
      1 => Ok(TextFilterConditionPB::IsNot),
      2 => Ok(TextFilterConditionPB::Contains),
      3 => Ok(TextFilterConditionPB::DoesNotContain),
      4 => Ok(TextFilterConditionPB::StartsWith),
      5 => Ok(TextFilterConditionPB::EndsWith),
      6 => Ok(TextFilterConditionPB::TextIsEmpty),
      7 => Ok(TextFilterConditionPB::TextIsNotEmpty),
      _ => Err(ErrorCode::InvalidData),
    }
  }
}

impl FromFilterString for TextFilterPB {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized,
  {
    TextFilterPB {
      condition: TextFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(TextFilterConditionPB::Is),
      content: filter.content.clone(),
    }
  }
}

impl std::convert::From<&Filter> for TextFilterPB {
  fn from(filter: &Filter) -> Self {
    TextFilterPB {
      condition: TextFilterConditionPB::try_from(filter.condition as u8)
        .unwrap_or(TextFilterConditionPB::Is),
      content: filter.content.clone(),
    }
  }
}
