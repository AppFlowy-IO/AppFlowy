use crate::entities::{
    GridLayoutPB, GridLayoutType, GridSettingPB, RepeatedGridFilterPB, RepeatedGridGroupPB, RepeatedGridSortPB,
};
use flowy_grid_data_model::revision::{FieldRevision, GridSettingRevision};
use flowy_sync::entities::grid::{CreateGridFilterParams, DeleteFilterParams, GridSettingChangesetParams};
use std::collections::HashMap;
use std::sync::Arc;

pub struct GridSettingChangesetBuilder {
    params: GridSettingChangesetParams,
}

impl GridSettingChangesetBuilder {
    pub fn new(grid_id: &str, layout_type: &GridLayoutType) -> Self {
        let params = GridSettingChangesetParams {
            grid_id: grid_id.to_string(),
            layout_type: layout_type.clone().into(),
            insert_filter: None,
            delete_filter: None,
            insert_group: None,
            delete_group: None,
            insert_sort: None,
            delete_sort: None,
        };
        Self { params }
    }

    pub fn insert_filter(mut self, params: CreateGridFilterParams) -> Self {
        self.params.insert_filter = Some(params);
        self
    }

    pub fn delete_filter(mut self, params: DeleteFilterParams) -> Self {
        self.params.delete_filter = Some(params);
        self
    }

    pub fn build(self) -> GridSettingChangesetParams {
        self.params
    }
}

pub fn make_grid_setting(grid_setting_rev: &GridSettingRevision, field_revs: &[Arc<FieldRevision>]) -> GridSettingPB {
    let current_layout_type: GridLayoutType = grid_setting_rev.layout.clone().into();
    let filters_by_field_id = grid_setting_rev
        .get_all_filter(field_revs)
        .map(|filters_by_field_id| {
            filters_by_field_id
                .into_iter()
                .map(|(k, v)| (k, v.into()))
                .collect::<HashMap<String, RepeatedGridFilterPB>>()
        })
        .unwrap_or_default();
    let groups_by_field_id = grid_setting_rev
        .get_all_group()
        .map(|groups_by_field_id| {
            groups_by_field_id
                .into_iter()
                .map(|(k, v)| (k, v.into()))
                .collect::<HashMap<String, RepeatedGridGroupPB>>()
        })
        .unwrap_or_default();
    let sorts_by_field_id = grid_setting_rev
        .get_all_sort()
        .map(|sorts_by_field_id| {
            sorts_by_field_id
                .into_iter()
                .map(|(k, v)| (k, v.into()))
                .collect::<HashMap<String, RepeatedGridSortPB>>()
        })
        .unwrap_or_default();

    GridSettingPB {
        layouts: GridLayoutPB::all(),
        current_layout_type,
        filters_by_field_id,
        groups_by_field_id,
        sorts_by_field_id,
    }
}
