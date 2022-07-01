use flowy_grid_data_model::revision::{FieldTypeRevision, GridLayoutRevision};

pub struct GridSettingChangesetParams {
    pub grid_id: String,
    pub layout_type: GridLayoutRevision,
    pub insert_filter: Option<CreateGridFilterParams>,
    pub delete_filter: Option<DeleteFilterParams>,
    pub insert_group: Option<CreateGridGroupParams>,
    pub delete_group: Option<String>,
    pub insert_sort: Option<CreateGridSortParams>,
    pub delete_sort: Option<String>,
}

impl GridSettingChangesetParams {
    pub fn is_filter_changed(&self) -> bool {
        self.insert_filter.is_some() || self.delete_filter.is_some()
    }
}
pub struct CreateGridFilterParams {
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub condition: u8,
    pub content: Option<String>,
}

pub struct DeleteFilterParams {
    pub filter_id: String,
    pub field_type_rev: FieldTypeRevision,
}
pub struct CreateGridGroupParams {
    pub field_id: Option<String>,
    pub sub_field_id: Option<String>,
}
pub struct CreateGridSortParams {
    pub field_id: Option<String>,
}

#[derive(Debug, Clone, Default)]
pub struct FieldChangesetParams {
    pub field_id: String,

    pub grid_id: String,

    pub name: Option<String>,

    pub desc: Option<String>,

    pub field_type: Option<FieldTypeRevision>,

    pub frozen: Option<bool>,

    pub visibility: Option<bool>,

    pub width: Option<i32>,

    pub type_option_data: Option<Vec<u8>>,
}
