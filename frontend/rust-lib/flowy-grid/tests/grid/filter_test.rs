use crate::grid::script::EditorScript::*;
use crate::grid::script::*;

use flowy_grid_data_model::entities::{
    CreateGridFilterParams, CreateGridFilterPayload, GridLayoutType, GridSettingChangesetParams, TextFilterCondition,
};

#[tokio::test]
async fn grid_filter_create_test() {
    let test = GridEditorTest::new().await;
    let field_rev = test.text_field();
    let payload = CreateGridFilterPayload::new(field_rev, TextFilterCondition::TextIsEmpty, Some("abc".to_owned()));
    let scripts = vec![InsertGridTableFilter { payload }, AssertTableFilterCount { count: 1 }];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
#[should_panic]
async fn grid_filter_invalid_condition_panic_test() {
    let test = GridEditorTest::new().await;
    let field_rev = test.text_field();

    // 100 is not a valid condition, so this test should be panic.
    let payload = CreateGridFilterPayload::new(field_rev, 100, Some("abc".to_owned()));
    let scripts = vec![InsertGridTableFilter { payload }];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_delete_test() {
    let mut test = GridEditorTest::new().await;
    let field_rev = test.text_field();
    let payload = CreateGridFilterPayload::new(field_rev, 100, Some("abc".to_owned()));
    let scripts = vec![InsertGridTableFilter { payload }, AssertTableFilterCount { count: 1 }];
    test.run_scripts(scripts).await;

    let filter = test.grid_filters().await.pop().unwrap();
    test.run_scripts(vec![
        DeleteGridTableFilter { filter_id: filter.id },
        AssertTableFilterCount { count: 0 },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_get_rows_test() {}
