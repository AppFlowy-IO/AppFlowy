use crate::revision::{gen_grid_group_id, FieldTypeRevision};
use serde::{Deserialize, Serialize};
use serde_json::Error;
use serde_repr::*;

pub trait GroupConfigurationContentSerde: Sized + Send + Sync {
    fn from_json(s: &str) -> Result<Self, serde_json::Error>;
    fn to_json(&self) -> Result<String, serde_json::Error>;
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GroupConfigurationRevision {
    pub id: String,
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub groups: Vec<GroupRevision>,
    // This content is serde in Json format
    pub content: String,
}

impl GroupConfigurationRevision {
    pub fn new<T>(field_id: String, field_type: FieldTypeRevision, content: T) -> Result<Self, serde_json::Error>
    where
        T: GroupConfigurationContentSerde,
    {
        let content = content.to_json()?;
        Ok(Self {
            id: gen_grid_group_id(),
            field_id,
            field_type_rev: field_type,
            groups: vec![],
            content,
        })
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct TextGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for TextGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_json(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct NumberGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for NumberGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_json(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct UrlGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for UrlGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_json(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct CheckboxGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for CheckboxGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }

    fn to_json(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct SelectOptionGroupConfigurationRevision {
    pub hide_empty: bool,
}

impl GroupConfigurationContentSerde for SelectOptionGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }

    fn to_json(&self) -> Result<String, Error> {
        serde_json::to_string(self)
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct GroupRevision {
    pub id: String,

    #[serde(default)]
    pub name: String,

    #[serde(default = "GROUP_REV_VISIBILITY")]
    pub visible: bool,
}

const GROUP_REV_VISIBILITY: fn() -> bool = || true;

impl GroupRevision {
    pub fn new(id: String, group_name: String) -> Self {
        Self {
            id,
            name: group_name,
            visible: true,
        }
    }

    pub fn default_group(id: String, group_name: String) -> Self {
        Self {
            id,
            name: group_name,
            visible: true,
        }
    }

    pub fn update_with_other(&mut self, other: &GroupRevision) {
        self.visible = other.visible
    }
}

#[derive(Default, Serialize, Deserialize)]
pub struct DateGroupConfigurationRevision {
    pub hide_empty: bool,
    pub condition: DateCondition,
}

impl GroupConfigurationContentSerde for DateGroupConfigurationRevision {
    fn from_json(s: &str) -> Result<Self, Error> {
        serde_json::from_str(s)
    }
    fn to_json(&self) -> Result<String, Error> {
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

#[cfg(test)]
mod tests {
    use crate::revision::{GroupConfigurationRevision, SelectOptionGroupConfigurationRevision};

    #[test]
    fn group_configuration_serde_test() {
        let content = SelectOptionGroupConfigurationRevision { hide_empty: false };
        let rev = GroupConfigurationRevision::new("1".to_owned(), 2, content).unwrap();
        let json = serde_json::to_string(&rev).unwrap();

        let rev: GroupConfigurationRevision = serde_json::from_str(&json).unwrap();
        let _content: SelectOptionGroupConfigurationRevision = serde_json::from_str(&rev.content).unwrap();
    }

    #[test]
    fn group_configuration_serde_test2() {
        let content = SelectOptionGroupConfigurationRevision { hide_empty: false };
        let content_json = serde_json::to_string(&content).unwrap();
        let rev = GroupConfigurationRevision::new("1".to_owned(), 2, content).unwrap();

        assert_eq!(rev.content, content_json);
    }
}
