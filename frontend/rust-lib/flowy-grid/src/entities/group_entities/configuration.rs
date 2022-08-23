use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_grid_data_model::revision::{GroupRecordRevision, SelectOptionGroupConfigurationRevision};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct UrlGroupConfigurationPB {
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

impl std::convert::From<SelectOptionGroupConfigurationRevision> for SelectOptionGroupConfigurationPB {
    fn from(rev: SelectOptionGroupConfigurationRevision) -> Self {
        Self {
            hide_empty: rev.hide_empty,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GroupRecordPB {
    #[pb(index = 1)]
    group_id: String,

    #[pb(index = 2)]
    visible: bool,
}

impl std::convert::From<GroupRecordRevision> for GroupRecordPB {
    fn from(rev: GroupRecordRevision) -> Self {
        Self {
            group_id: rev.group_id,
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
pub enum DateCondition {
    Relative = 0,
    Day = 1,
    Week = 2,
    Month = 3,
    Year = 4,
}

impl std::default::Default for DateCondition {
    fn default() -> Self {
        DateCondition::Relative
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxGroupConfigurationPB {
    #[pb(index = 1)]
    pub(crate) hide_empty: bool,
}
