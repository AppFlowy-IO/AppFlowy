use crate::{
  entities::FieldType,
  services::group::{DateCondition, DateGroupConfiguration, Group},
};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyResult;

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

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct DateGroupConfigurationPB {
  #[pb(index = 1)]
  pub condition: DateConditionPB,

  #[pb(index = 2)]
  hide_empty: bool,
}

impl From<DateGroupConfigurationPB> for DateGroupConfiguration {
  fn from(data: DateGroupConfigurationPB) -> Self {
    Self {
      condition: data.condition.into(),
      hide_empty: data.hide_empty,
    }
  }
}

impl From<DateGroupConfiguration> for DateGroupConfigurationPB {
  fn from(data: DateGroupConfiguration) -> Self {
    Self {
      condition: data.condition.into(),
      hide_empty: data.hide_empty,
    }
  }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, Default)]
#[repr(u8)]
pub enum DateConditionPB {
  #[default]
  Relative = 0,
  Day = 1,
  Week = 2,
  Month = 3,
  Year = 4,
}

impl From<DateConditionPB> for DateCondition {
  fn from(data: DateConditionPB) -> Self {
    match data {
      DateConditionPB::Relative => DateCondition::Relative,
      DateConditionPB::Day => DateCondition::Day,
      DateConditionPB::Week => DateCondition::Week,
      DateConditionPB::Month => DateCondition::Month,
      DateConditionPB::Year => DateCondition::Year,
    }
  }
}

impl From<DateCondition> for DateConditionPB {
  fn from(data: DateCondition) -> Self {
    match data {
      DateCondition::Relative => DateConditionPB::Relative,
      DateCondition::Day => DateConditionPB::Day,
      DateCondition::Week => DateConditionPB::Week,
      DateCondition::Month => DateConditionPB::Month,
      DateCondition::Year => DateConditionPB::Year,
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxGroupConfigurationPB {
  #[pb(index = 1)]
  pub(crate) hide_empty: bool,
}

pub fn group_config_pb_to_json_str<T: Into<Bytes>>(
  bytes: T,
  field_type: &FieldType,
) -> FlowyResult<String> {
  let bytes = bytes.into();
  match field_type {
    FieldType::DateTime => DateGroupConfigurationPB::try_from(bytes)
      .map(|pb| DateGroupConfiguration::from(pb).to_json())?,
    _ => Ok("".to_string()),
  }
}

pub fn group_config_json_to_pb(setting_content: String, field_type: &FieldType) -> Bytes {
  match field_type {
    FieldType::DateTime => {
      let date_group_config = DateGroupConfiguration::from_json(setting_content.as_ref()).unwrap();
      DateGroupConfigurationPB::from(date_group_config)
        .try_into()
        .unwrap()
    },
    _ => Bytes::new(),
  }
}
