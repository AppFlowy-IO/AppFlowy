use crate::services::filter::FromFilterString;
use database_model::FilterRevision;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxFilterPB {
  #[pb(index = 1)]
  pub condition: CheckboxFilterConditionPB,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum CheckboxFilterConditionPB {
  IsChecked = 0,
  IsUnChecked = 1,
}

impl std::convert::From<CheckboxFilterConditionPB> for u32 {
  fn from(value: CheckboxFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::default::Default for CheckboxFilterConditionPB {
  fn default() -> Self {
    CheckboxFilterConditionPB::IsChecked
  }
}

impl std::convert::TryFrom<u8> for CheckboxFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(CheckboxFilterConditionPB::IsChecked),
      1 => Ok(CheckboxFilterConditionPB::IsUnChecked),
      _ => Err(ErrorCode::InvalidData),
    }
  }
}

impl FromFilterString for CheckboxFilterPB {
  fn from_filter_rev(filter_rev: &FilterRevision) -> Self
  where
    Self: Sized,
  {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::try_from(filter_rev.condition)
        .unwrap_or(CheckboxFilterConditionPB::IsChecked),
    }
  }
}

impl std::convert::From<&FilterRevision> for CheckboxFilterPB {
  fn from(rev: &FilterRevision) -> Self {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::try_from(rev.condition)
        .unwrap_or(CheckboxFilterConditionPB::IsChecked),
    }
  }
}
