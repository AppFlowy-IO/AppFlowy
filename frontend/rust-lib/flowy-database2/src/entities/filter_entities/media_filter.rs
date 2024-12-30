use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct MediaFilterPB {
  #[pb(index = 1)]
  pub condition: MediaFilterConditionPB,

  #[pb(index = 2)]
  pub content: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum MediaFilterConditionPB {
  #[default]
  MediaIsEmpty = 0,
  MediaIsNotEmpty = 1,
}

impl std::convert::From<MediaFilterConditionPB> for u32 {
  fn from(value: MediaFilterConditionPB) -> Self {
    value as u32
  }
}

impl std::convert::TryFrom<u8> for MediaFilterConditionPB {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(MediaFilterConditionPB::MediaIsEmpty),
      1 => Ok(MediaFilterConditionPB::MediaIsNotEmpty),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

impl ParseFilterData for MediaFilterPB {
  fn parse(condition: u8, content: String) -> Self {
    Self {
      condition: MediaFilterConditionPB::try_from(condition)
        .unwrap_or(MediaFilterConditionPB::MediaIsEmpty),
      content,
    }
  }
}
