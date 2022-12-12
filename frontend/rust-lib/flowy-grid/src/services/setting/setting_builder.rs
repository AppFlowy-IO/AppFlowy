use crate::entities::{AlterFilterParams, DeleteFilterParams, GridLayout, GridSettingChangesetParams};

pub struct GridSettingChangesetBuilder {
    params: GridSettingChangesetParams,
}

impl GridSettingChangesetBuilder {
    pub fn new(grid_id: &str, layout_type: &GridLayout) -> Self {
        let params = GridSettingChangesetParams {
            grid_id: grid_id.to_string(),
            layout_type: layout_type.clone().into(),
            insert_filter: None,
            delete_filter: None,
            insert_group: None,
            delete_group: None,
            alert_sort: None,
            delete_sort: None,
        };
        Self { params }
    }

    pub fn insert_filter(mut self, params: AlterFilterParams) -> Self {
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
