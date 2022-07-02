use crate::revision::FieldTypeRevision;
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::sync::Arc;

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
    // layout:
    //       field_id:
    //               FieldType: GridFilterRevision
    //               FieldType: GridFilterRevision
    // layout:
    //       field_id:
    //               FieldType: GridFilterRevision
    //       field_id:
    //               FieldType: GridFilterRevision
    #[serde(with = "indexmap::serde_seq")]
    pub filters: IndexMap<GridLayoutRevision, IndexMap<String, GridFilterRevisionMap>>,

    #[serde(skip, with = "indexmap::serde_seq")]
    pub groups: IndexMap<GridLayoutRevision, Vec<GridGroupRevision>>,

    #[serde(skip, with = "indexmap::serde_seq")]
    pub sorts: IndexMap<GridLayoutRevision, Vec<GridSortRevision>>,
}

impl GridSettingRevision {
    pub fn get_mut_filters(
        &mut self,
        layout: &GridLayoutRevision,
        field_id: &str,
        field_type: &FieldTypeRevision,
    ) -> Option<&mut Vec<Arc<GridFilterRevision>>> {
        self.filters
            .get_mut(layout)
            .and_then(|filter_rev_map_by_field_id| filter_rev_map_by_field_id.get_mut(field_id))
            .and_then(|filter_rev_map| filter_rev_map.get_mut(field_type))
    }

    pub fn get_filters(
        &self,
        layout: &GridLayoutRevision,
        field_id: &str,
        field_type: &FieldTypeRevision,
    ) -> Option<Vec<Arc<GridFilterRevision>>> {
        self.filters
            .get(layout)
            .and_then(|filter_rev_map_by_field_id| filter_rev_map_by_field_id.get(field_id))
            .and_then(|filter_rev_map| filter_rev_map.get(field_type))
            .cloned()
    }

    pub fn insert_filter(
        &mut self,
        layout: &GridLayoutRevision,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_rev: GridFilterRevision,
    ) {
        let filter_rev_map_by_field_id = self.filters.entry(layout.clone()).or_insert_with(IndexMap::new);
        let filter_rev_map = filter_rev_map_by_field_id
            .entry(field_id.to_string())
            .or_insert_with(GridFilterRevisionMap::new);

        filter_rev_map
            .entry(field_type.to_owned())
            .or_insert_with(Vec::new)
            .push(Arc::new(filter_rev))
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, Eq, PartialEq)]
#[serde(transparent)]
pub struct GridFilterRevisionMap {
    #[serde(with = "indexmap::serde_seq")]
    pub filter_by_field_type: IndexMap<FieldTypeRevision, Vec<Arc<GridFilterRevision>>>,
}

impl GridFilterRevisionMap {
    pub fn new() -> Self {
        GridFilterRevisionMap::default()
    }
}

impl std::ops::Deref for GridFilterRevisionMap {
    type Target = IndexMap<FieldTypeRevision, Vec<Arc<GridFilterRevision>>>;

    fn deref(&self) -> &Self::Target {
        &self.filter_by_field_type
    }
}

impl std::ops::DerefMut for GridFilterRevisionMap {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.filter_by_field_type
    }
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

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq, Hash)]
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
