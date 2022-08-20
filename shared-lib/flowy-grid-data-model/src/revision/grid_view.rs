use crate::revision::{
    FieldRevision, FieldTypeRevision, FilterConfiguration, FilterConfigurationRevision, FilterConfigurationsByFieldId,
    GroupConfiguration, GroupConfigurationRevision, GroupConfigurationsByFieldId,
};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::sync::Arc;

#[allow(dead_code)]
pub fn gen_grid_view_id() -> String {
    nanoid!(6)
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum LayoutRevision {
    Table = 0,
    Board = 1,
}

impl ToString for LayoutRevision {
    fn to_string(&self) -> String {
        let layout_rev = self.clone() as u8;
        layout_rev.to_string()
    }
}

impl std::default::Default for LayoutRevision {
    fn default() -> Self {
        LayoutRevision::Table
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridViewRevision {
    pub view_id: String,

    pub grid_id: String,

    pub layout: LayoutRevision,

    pub filters: FilterConfiguration,

    #[serde(default)]
    pub groups: GroupConfiguration,

    // For the moment, we just use the order returned from the GridRevision
    #[allow(dead_code)]
    #[serde(skip, rename = "row")]
    pub row_orders: Vec<RowOrderRevision>,
}

impl GridViewRevision {
    pub fn new(grid_id: String, view_id: String) -> Self {
        GridViewRevision {
            view_id,
            grid_id,
            layout: Default::default(),
            filters: Default::default(),
            groups: Default::default(),
            row_orders: vec![],
        }
    }

    pub fn get_all_groups(&self, field_revs: &[Arc<FieldRevision>]) -> Option<GroupConfigurationsByFieldId> {
        self.groups.get_all_objects(field_revs)
    }

    pub fn get_groups(
        &self,
        field_id: &str,
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Arc<GroupConfigurationRevision>> {
        let mut groups = self.groups.get_objects(field_id, field_type_rev)?;
        if groups.is_empty() {
            debug_assert_eq!(groups.len(), 1);
            Some(groups.pop().unwrap())
        } else {
            None
        }
    }

    pub fn get_mut_groups(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
    ) -> Option<&mut Vec<Arc<GroupConfigurationRevision>>> {
        self.groups.get_mut_objects(field_id, field_type)
    }

    pub fn insert_group(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        group_rev: GroupConfigurationRevision,
    ) {
        // only one group can be set
        self.groups.remove_all();
        self.groups.insert_object(field_id, field_type, group_rev);
    }

    pub fn get_all_filters(&self, field_revs: &[Arc<FieldRevision>]) -> Option<FilterConfigurationsByFieldId> {
        self.filters.get_all_objects(field_revs)
    }

    pub fn get_filters(
        &self,
        field_id: &str,
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Vec<Arc<FilterConfigurationRevision>>> {
        self.filters.get_objects(field_id, field_type_rev)
    }

    pub fn get_mut_filters(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
    ) -> Option<&mut Vec<Arc<FilterConfigurationRevision>>> {
        self.filters.get_mut_objects(field_id, field_type)
    }

    pub fn insert_filter(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_rev: FilterConfigurationRevision,
    ) {
        self.filters.insert_object(field_id, field_type, filter_rev);
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RowOrderRevision {
    pub row_id: String,
}
