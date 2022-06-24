use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;

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
    pub layout: GridLayoutRevision,

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
    pub condition: u8,
    pub content: Option<String>,
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
