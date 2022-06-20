use crate::entities::{GridFilter, GridGroup, GridLayoutType, GridSetting, GridSort};
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GridSettingRevision {
    #[serde(with = "indexmap::serde_seq")]
    pub filter: IndexMap<GridLayoutRevision, GridFilterRevision>,

    #[serde(with = "indexmap::serde_seq")]
    pub group: IndexMap<GridLayoutRevision, GridGroupRevision>,

    #[serde(with = "indexmap::serde_seq")]
    pub sort: IndexMap<GridLayoutRevision, GridSortRevision>,
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

impl std::convert::From<GridLayoutRevision> for GridLayoutType {
    fn from(rev: GridLayoutRevision) -> Self {
        match rev {
            GridLayoutRevision::Table => GridLayoutType::Table,
            GridLayoutRevision::Board => GridLayoutType::Board,
        }
    }
}

impl std::convert::From<GridLayoutType> for GridLayoutRevision {
    fn from(layout: GridLayoutType) -> Self {
        match layout {
            GridLayoutType::Table => GridLayoutRevision::Table,
            GridLayoutType::Board => GridLayoutRevision::Board,
        }
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
    pub field_id: Option<String>,
}

impl std::convert::From<GridFilterRevision> for GridFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridFilter { field_id: rev.field_id }
    }
}

impl std::convert::From<GridGroupRevision> for GridGroup {
    fn from(rev: GridGroupRevision) -> Self {
        GridGroup {
            group_field_id: rev.group_field_id,
            sub_group_field_id: rev.sub_group_field_id,
        }
    }
}

impl std::convert::From<GridSortRevision> for GridSort {
    fn from(rev: GridSortRevision) -> Self {
        GridSort { field_id: rev.field_id }
    }
}

impl std::convert::From<GridSettingRevision> for GridSetting {
    fn from(rev: GridSettingRevision) -> Self {
        let filter: HashMap<String, GridFilter> = rev
            .filter
            .into_iter()
            .map(|(layout_rev, filter_rev)| (layout_rev.to_string(), filter_rev.into()))
            .collect();

        let group: HashMap<String, GridGroup> = rev
            .group
            .into_iter()
            .map(|(layout_rev, group_rev)| (layout_rev.to_string(), group_rev.into()))
            .collect();

        let sort: HashMap<String, GridSort> = rev
            .sort
            .into_iter()
            .map(|(layout_rev, sort_rev)| (layout_rev.to_string(), sort_rev.into()))
            .collect();

        GridSetting { filter, group, sort }
    }
}
