use crate::revision::filter_rev::GridFilterRevision;
use crate::revision::group_rev::GridGroupRevision;
use crate::revision::{FieldRevision, FieldTypeRevision};
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::collections::HashMap;
use std::fmt::Debug;
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

    /// Each layout contains multiple key/value.
    /// Key:    field_id
    /// Value:  this value contains key/value.
    ///         Key: FieldType,
    ///         Value: the corresponding filters.
    #[serde(with = "indexmap::serde_seq")]
    filters: IndexMap<GridLayoutRevision, IndexMap<String, GridFilterRevisionMap>>,

    /// Each layout contains multiple key/value.
    /// Key:    field_id
    /// Value:  this value contains key/value.
    ///         Key: FieldType,
    ///         Value: the corresponding groups.
    #[serde(skip, with = "indexmap::serde_seq")]
    pub groups: IndexMap<GridLayoutRevision, IndexMap<String, GridGroupRevisionMap>>,

    #[serde(skip, with = "indexmap::serde_seq")]
    pub sorts: IndexMap<GridLayoutRevision, Vec<GridSortRevision>>,
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

pub type FiltersByFieldId = HashMap<String, Vec<Arc<GridFilterRevision>>>;
pub type GroupsByFieldId = HashMap<String, Vec<Arc<GridGroupRevision>>>;
pub type SortsByFieldId = HashMap<String, Vec<Arc<GridSortRevision>>>;
impl GridSettingRevision {
    pub fn get_all_group(&self) -> Option<GroupsByFieldId> {
        None
    }

    pub fn get_mut_groups(
        &mut self,
        layout: &GridLayoutRevision,
        field_id: &str,
        field_type: &FieldTypeRevision,
    ) -> Option<&mut Vec<Arc<GridGroupRevision>>> {
        self.groups
            .get_mut(layout)
            .and_then(|group_rev_map_by_field_id| group_rev_map_by_field_id.get_mut(field_id))
            .and_then(|group_rev_map| group_rev_map.get_mut(field_type))
    }

    pub fn insert_group(
        &mut self,
        layout: &GridLayoutRevision,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_rev: GridGroupRevision,
    ) {
        let filter_rev_map_by_field_id = self.groups.entry(layout.clone()).or_insert_with(IndexMap::new);
        let filter_rev_map = filter_rev_map_by_field_id
            .entry(field_id.to_string())
            .or_insert_with(GridGroupRevisionMap::new);

        filter_rev_map
            .entry(field_type.to_owned())
            .or_insert_with(Vec::new)
            .push(Arc::new(filter_rev))
    }

    pub fn get_all_sort(&self) -> Option<SortsByFieldId> {
        None
    }

    /// Return the Filters of the current layout
    pub fn get_all_filter(&self, field_revs: &[Arc<FieldRevision>]) -> Option<FiltersByFieldId> {
        let layout = &self.layout;
        // Acquire the read lock of the filters.
        let filter_rev_map_by_field_id = self.filters.get(layout)?;
        // Get the filters according to the FieldType, so we need iterate the field_revs.
        let filters_by_field_id = field_revs
            .iter()
            .flat_map(|field_rev| {
                let field_type = &field_rev.field_type_rev;
                let field_id = &field_rev.id;

                let filter_rev_map: &GridFilterRevisionMap = filter_rev_map_by_field_id.get(field_id)?;
                let filters: Vec<Arc<GridFilterRevision>> = filter_rev_map.get(field_type)?.clone();
                Some((field_rev.id.clone(), filters))
            })
            .collect::<FiltersByFieldId>();
        Some(filters_by_field_id)
    }

    #[allow(dead_code)]
    fn get_filter_rev_map(&self, layout: &GridLayoutRevision, field_id: &str) -> Option<&GridFilterRevisionMap> {
        let filter_rev_map_by_field_id = self.filters.get(layout)?;
        filter_rev_map_by_field_id.get(field_id)
    }

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
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Vec<Arc<GridFilterRevision>>> {
        self.filters
            .get(layout)
            .and_then(|filter_rev_map_by_field_id| filter_rev_map_by_field_id.get(field_id))
            .and_then(|filter_rev_map| filter_rev_map.get(field_type_rev))
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

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct GridSortRevision {
    pub id: String,
    pub field_id: Option<String>,
}

pub type GridFilterRevisionMap = GridObjectRevisionMap<GridFilterRevision>;
pub type GridGroupRevisionMap = GridObjectRevisionMap<GridGroupRevision>;

#[derive(Debug, Clone, Serialize, Deserialize, Default, Eq, PartialEq)]
#[serde(transparent)]
pub struct GridObjectRevisionMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    #[serde(with = "indexmap::serde_seq")]
    pub object_by_field_type: IndexMap<FieldTypeRevision, Vec<Arc<T>>>,
}

impl<T> GridObjectRevisionMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    pub fn new() -> Self {
        GridObjectRevisionMap::default()
    }
}

impl<T> std::ops::Deref for GridObjectRevisionMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    type Target = IndexMap<FieldTypeRevision, Vec<Arc<T>>>;

    fn deref(&self) -> &Self::Target {
        &self.object_by_field_type
    }
}

impl<T> std::ops::DerefMut for GridObjectRevisionMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.object_by_field_type
    }
}
