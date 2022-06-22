use crate::grid::script::EditorScript::*;
use crate::grid::script::*;

use flowy_grid_data_model::entities::{
    CreateGridFilterParams, CreateGridFilterPayload, GridLayoutType, GridSettingChangesetParams, TextFilterCondition,
};

#[tokio::test]
async fn grid_setting_create_text_filter_test() {
    let test = GridEditorTest::new().await;
    let field_rev = test.text_field();
    let condition = TextFilterCondition::TextIsEmpty as i32;

    let scripts = vec![
        InsertGridTableFilter {
            payload: CreateGridFilterPayload {
                field_id: field_rev.id.clone(),
                field_type: field_rev.field_type.clone(),
                condition,
                content: Some("abc".to_owned()),
            },
        },
        AssertTableFilterCount { count: 1 },
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
#[should_panic]
async fn grid_setting_create_text_filter_panic_test() {
    let test = GridEditorTest::new().await;
    let field_rev = test.text_field();
    let scripts = vec![InsertGridTableFilter {
        payload: CreateGridFilterPayload {
            field_id: field_rev.id.clone(),
            field_type: field_rev.field_type.clone(),
            condition: 20, // Invalid condition type
            content: Some("abc".to_owned()),
        },
    }];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_setting_delete_text_filter_test() {
    let mut test = GridEditorTest::new().await;
    let field_rev = test.text_field();
    let condition = TextFilterCondition::TextIsEmpty as i32;

    let scripts = vec![
        InsertGridTableFilter {
            payload: CreateGridFilterPayload {
                field_id: field_rev.id.clone(),
                field_type: field_rev.field_type.clone(),
                condition,
                content: Some("abc".to_owned()),
            },
        },
        AssertTableFilterCount { count: 1 },
    ];

    test.run_scripts(scripts).await;
    let filter = test.grid_filters().await.pop().unwrap();

    test.run_scripts(vec![
        DeleteGridTableFilter { filter_id: filter.id },
        AssertTableFilterCount { count: 0 },
    ])
    .await;
}
#[tokio::test]
async fn grid_setting_sort_test() {}
