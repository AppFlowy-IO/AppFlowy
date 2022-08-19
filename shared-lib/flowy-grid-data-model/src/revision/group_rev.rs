use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Default, Serialize, Deserialize)]
pub struct TextGroupConfigurationRevision {
    pub hide_empty: bool,
}

#[derive(Default, Serialize, Deserialize)]
pub struct NumberGroupConfigurationRevision {
    pub hide_empty: bool,
}

#[derive(Default, Serialize, Deserialize)]
pub struct UrlGroupConfigurationRevision {
    pub hide_empty: bool,
}

#[derive(Default, Serialize, Deserialize)]
pub struct CheckboxGroupConfigurationRevision {
    pub hide_empty: bool,
}

#[derive(Default, Serialize, Deserialize)]
pub struct SelectOptionGroupConfigurationRevision {
    pub hide_empty: bool,
    pub groups: Vec<GroupRecordRevision>,
}

#[derive(Default, Serialize, Deserialize)]
pub struct GroupRecordRevision {
    pub group_id: String,

    #[serde(default = "DEFAULT_GROUP_RECORD_VISIBILITY")]
    pub visible: bool,
}
const DEFAULT_GROUP_RECORD_VISIBILITY: fn() -> bool = || true;

#[derive(Default, Serialize, Deserialize)]
pub struct DateGroupConfigurationRevision {
    pub hide_empty: bool,
    pub condition: DateCondition,
}

#[derive(Serialize_repr, Deserialize_repr)]
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
