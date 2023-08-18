use crate::services::group::Group;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

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
  pub condition: DateCondition,

  #[pb(index = 2)]
  hide_empty: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
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

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxGroupConfigurationPB {
  #[pb(index = 1)]
  pub(crate) hide_empty: bool,
}
