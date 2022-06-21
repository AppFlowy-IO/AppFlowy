use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::str::FromStr;

pub fn gen_grid_filter_id() -> String {
    nanoid!(6)
}

pub fn gen_grid_group_id() -> String {
    nanoid!(6)
}

pub fn gen_grid_sort_id() -> String {
    nanoid!(6)
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, Eq, PartialEq)]
pub struct GridSettingRevision {
    #[serde(with = "indexmap::serde_seq")]
    pub filter: IndexMap<GridLayoutRevision, Vec<GridFilterRevision>>,

    #[serde(skip, with = "indexmap::serde_seq")]
    pub group: IndexMap<GridLayoutRevision, Vec<GridGroupRevision>>,

    #[serde(skip, with = "indexmap::serde_seq")]
    pub sort: IndexMap<GridLayoutRevision, Vec<GridSortRevision>>,
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum GridLayoutRevision {
    Table = 0,
    Board = 1,
}

impl ToString for GridLayoutRevision {
    fn to_string(&self) -> String {
        let layout_rev = self.clone() as u8;
        layout_rev.to_string()
    }
}

impl std::default::Default for GridLayoutRevision {
    fn default() -> Self {
        GridLayoutRevision::Table
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridFilterRevision {
    pub id: String,
    pub field_id: String,
    pub info: FilterInfoRevision,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridGroupRevision {
    pub id: String,
    pub field_id: Option<String>,
    pub sub_field_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridSortRevision {
    pub id: String,
    pub field_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct FilterInfoRevision {
    pub condition: Option<String>,
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
