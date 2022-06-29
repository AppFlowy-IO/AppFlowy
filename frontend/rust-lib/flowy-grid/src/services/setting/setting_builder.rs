use flowy_grid_data_model::entities::{CreateGridFilterParams, GridLayoutType, GridSettingChangesetParams};

pub struct GridSettingChangesetBuilder {
    params: GridSettingChangesetParams,
}

impl GridSettingChangesetBuilder {
    pub fn new(grid_id: &str, layout_type: &GridLayoutType) -> Self {
        let params = GridSettingChangesetParams {
            grid_id: grid_id.to_string(),
            layout_type: layout_type.clone(),
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

    pub fn delete_filter(mut self, filter_id: &str) -> Self {
        self.params.delete_filter = Some(filter_id.to_string());
        self
    }

    pub fn build(self) -> GridSettingChangesetParams {
        self.params
    }
}
