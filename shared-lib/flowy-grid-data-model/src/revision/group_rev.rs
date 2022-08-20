use crate::revision::{gen_grid_group_id, FieldTypeRevision};
use serde::{Deserialize, Serialize};
use serde_json::Error;
use serde_repr::*;

pub trait GroupConfigurationContentSerde: Sized {
    fn from_configuration(s: &str) -> Result<Self, serde_json::Error>;
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GroupConfigurationRevision {
    pub id: String,
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub content: String,
}

impl GroupConfigurationRevision {
    pub fn new<T>(field_id: String, field_type: FieldTypeRevision, content: T) -> Result<Self, serde_json::Error>
    where
        T: serde::Serialize,
    {
        let content = serde_json::to_string(&content)?;
        Ok(Self {
            id: gen_grid_group_id(),
            field_id,
            field_type_rev: field_type,
            content,
        })
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct TextGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for TextGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct NumberGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for NumberGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct UrlGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for UrlGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct CheckboxGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for CheckboxGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct SelectOptionGroupConfigurationRevision {
    pub hide_empty: bool,
    pub groups: Vec<GroupRecordRevision>,
}

impl GroupConfigurationContentSerde for SelectOptionGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
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

impl GroupConfigurationContentSerde for DateGroupConfigurationRevision {
    fn from_configuration(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
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
