use crate::services::group::Group;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};

pub trait GroupConfigurationContentSerde: Sized + Send + Sync {
  fn from_json(s: &str) -> Result<Self, serde_json::Error>;
  fn to_json(&self) -> Result<String, serde_json::Error>;
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct URLGroupConfigurationPB {
  #[pb(index = 1)]
  hide_empty: bool,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TextGroupConfigurationPB {
  #[pb(index = 1)]
  hide_empty: bool,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionGroupConfigurationPB {
  #[pb(index = 1)]
  hide_empty: bool,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GroupRecordPB {
  #[pb(index = 1)]
  group_id: String,

  #[pb(index = 2)]
  visible: bool,
}

impl std::convert::From<Group> for GroupRecordPB {
  fn from(rev: Group) -> Self {
    Self {
      group_id: rev.id,
      visible: rev.visible,
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct NumberGroupConfigurationPB {
  #[pb(index = 1)]
  hide_empty: bool,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone, Serialize, Deserialize)]
pub struct DateGroupConfigurationPB {
  #[pb(index = 1)]
  pub condition: DateCondition,

  #[pb(index = 2)]
  pub hide_empty: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
#[derive(Default)]
pub enum DateCondition {
  #[default]
  Relative = 0,
  Day = 1,
  Week = 2,
  Month = 3,
  Year = 4,
}

impl GroupConfigurationContentSerde for DateGroupConfigurationPB {
  fn from_json(s: &str) -> Result<Self, serde_json::Error> {
    serde_json::from_str(s)
  }
  fn to_json(&self) -> Result<String, serde_json::Error> {
    serde_json::to_string(self)
  }
}

impl std::convert::TryFrom<u8> for DateCondition {
  type Error = ErrorCode;

  fn try_from(value: u8) -> Result<Self, Self::Error> {
    match value {
      0 => Ok(DateCondition::Relative),
      1 => Ok(DateCondition::Day),
      2 => Ok(DateCondition::Week),
      3 => Ok(DateCondition::Month),
      4 => Ok(DateCondition::Year),
      _ => Err(ErrorCode::InvalidParams),
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxGroupConfigurationPB {
  #[pb(index = 1)]
  pub(crate) hide_empty: bool,
}
