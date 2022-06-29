use crate::entities::NumberFilterCondition;
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::str::FromStr;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridFilterRevision {
    pub id: String,
    pub field_id: String,
    pub condition: u8,
    pub content: Option<String>,
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum TextFilterConditionRevision {
    Is = 0,
    IsNot = 1,
    Contains = 2,
    DoesNotContain = 3,
    StartsWith = 4,
    EndsWith = 5,
    IsEmpty = 6,
    IsNotEmpty = 7,
}

impl ToString for TextFilterConditionRevision {
    fn to_string(&self) -> String {
        (self.clone() as u8).to_string()
    }
}

impl FromStr for TextFilterConditionRevision {
    type Err = serde_json::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let rev = serde_json::from_str(s)?;
        Ok(rev)
    }
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum NumberFilterConditionRevision {
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    LessThan = 3,
    GreaterThanOrEqualTo = 4,
    LessThanOrEqualTo = 5,
    IsEmpty = 6,
    IsNotEmpty = 7,
}

impl ToString for NumberFilterConditionRevision {
    fn to_string(&self) -> String {
        (self.clone() as u8).to_string()
    }
}

impl FromStr for NumberFilterConditionRevision {
    type Err = serde_json::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let rev = serde_json::from_str(s)?;
        Ok(rev)
    }
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum SelectOptionConditionRevision {
    OptionIs = 0,
    OptionIsNot = 1,
    OptionIsEmpty = 2,
    OptionIsNotEmpty = 3,
}

impl ToString for SelectOptionConditionRevision {
    fn to_string(&self) -> String {
        (self.clone() as u8).to_string()
    }
}

impl FromStr for SelectOptionConditionRevision {
    type Err = serde_json::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let rev = serde_json::from_str(s)?;
        Ok(rev)
    }
}
