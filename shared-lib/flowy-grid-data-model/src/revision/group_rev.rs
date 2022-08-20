use crate::revision::{gen_grid_group_id, FieldTypeRevision};
use serde::{Deserialize, Serialize};
use serde_json::Error;
use serde_repr::*;

pub trait GroupConfigurationContent: Sized {
    fn from_configuration_content(s: &str) -> Result<Self, serde_json::Error>;

    fn get_groups(&self) -> &[GroupRecordRevision] {
        &[]
    }

    fn mut_group<F>(&mut self, _group_id: &str, _f: F)
    where
        F: FnOnce(&mut GroupRecordRevision),
    {
    }

    fn set_groups(&mut self, _new_groups: Vec<GroupRecordRevision>) {}

    fn to_configuration_content(&self) -> Result<String, serde_json::Error>;
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

impl GroupConfigurationContent for TextGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct NumberGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContent for NumberGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct UrlGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContent for UrlGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct CheckboxGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContent for CheckboxGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }

    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct SelectOptionGroupConfigurationRevision {
    pub hide_empty: bool,
    pub groups: Vec<GroupRecordRevision>,
}

impl GroupConfigurationContent for SelectOptionGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }

    fn get_groups(&self) -> &[GroupRecordRevision] {
        &self.groups
    }

    fn mut_group<F>(&mut self, group_id: &str, f: F)
    where
        F: FnOnce(&mut GroupRecordRevision),
    {
        match self.groups.iter_mut().find(|group| group.group_id == group_id) {
            None => {}
            Some(group) => f(group),
        }
    }

    fn set_groups(&mut self, new_groups: Vec<GroupRecordRevision>) {
        self.groups = new_groups;
    }

    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Clone, Default, Serialize, Deserialize)]
pub struct GroupRecordRevision {
    pub group_id: String,

    #[serde(default = "DEFAULT_GROUP_RECORD_VISIBILITY")]
    pub visible: bool,
}
const DEFAULT_GROUP_RECORD_VISIBILITY: fn() -> bool = || true;

impl GroupRecordRevision {
    pub fn new(group_id: String) -> Self {
        Self {
            group_id,
            visible: true,
        }
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct DateGroupConfigurationRevision {
    pub hide_empty: bool,
    pub condition: DateCondition,
}

impl GroupConfigurationContent for DateGroupConfigurationRevision {
    fn from_configuration_content(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_configuration_content(&self) -> Result<String, Error> {
        serde_json::to_string(self)
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
