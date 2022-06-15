use crate::entities::{ViewFilter, ViewGroup, ViewSort};
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridInfoRevision {
    pub filter: GridFilterRevision,
    pub group: GridGroupRevision,
    pub sort: GridSortRevision,
    pub layout: GridLayoutRevision,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridLayoutRevision {
    pub ty: GridLayoutType,
}

#[derive(Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum GridLayoutType {
    Table = 0,
    Board = 1,
}

impl std::default::Default for GridLayoutType {
    fn default() -> Self {
        GridLayoutType::Table
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridFilterRevision {
    pub field_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridGroupRevision {
    pub group_field_id: Option<String>,
    pub sub_group_field_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridSortRevision {
    field_id: Option<String>,
}

impl std::convert::From<GridFilterRevision> for ViewFilter {
    fn from(rev: GridFilterRevision) -> Self {
        ViewFilter { field_id: rev.field_id }
    }
}

impl std::convert::From<GridGroupRevision> for ViewGroup {
    fn from(rev: GridGroupRevision) -> Self {
        ViewGroup {
            group_field_id: rev.group_field_id,
            sub_group_field_id: rev.sub_group_field_id,
        }
    }
}

impl std::convert::From<GridSortRevision> for ViewSort {
    fn from(rev: GridSortRevision) -> Self {
        ViewSort { field_id: rev.field_id }
    }
}
