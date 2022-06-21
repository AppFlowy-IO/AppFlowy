use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid_data_model::entities::{
    CreateGridFilterParams, CreateGridFilterPayload, GridLayoutType, GridSettingChangesetParams,
};
use flowy_grid_data_model::revision::GridSettingRevision;

#[tokio::test]
async fn grid_setting_create_filter_test() {
    let test = GridEditorTest::new().await;

    let layout_type = GridLayoutType::Table;
    let field_rev = test.field_revs.last().unwrap();
    let create_params: CreateGridFilterParams = CreateGridFilterPayload {
        field_id: field_rev.id.clone(),
        field_type: field_rev.field_type.clone(),
    }
    .try_into()
    .unwrap();
    let params = GridSettingChangesetParams::from_insert_filter(&test.grid_id, layout_type, create_params);

    let scripts = vec![UpdateGridSetting { params }];
    GridEditorTest::new().await.run_scripts(scripts).await;

    // let mut expected_grid_setting = test.get_grid_setting().await;
}

#[tokio::test]
async fn grid_setting_sort_test() {}
