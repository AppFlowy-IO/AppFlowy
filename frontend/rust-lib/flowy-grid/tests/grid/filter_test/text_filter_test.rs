use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::*;
use flowy_grid::entities::{CreateFilterPayloadPB, FieldType, TextFilterCondition, TextFilterPB};
use flowy_grid::services::filter::FilterType;

#[tokio::test]
async fn grid_filter_text_is_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::TextIsEmpty,
            content: "".to_string(),
        },
        AssertFilterCount { count: 1 },
        AssertFilterChanged {
            visible_row_len: 1,
            hide_row_len: 4,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_text_is_not_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::TextIsNotEmpty,
            content: "".to_string(),
        },
        AssertFilterCount { count: 1 },
        AssertFilterChanged {
            visible_row_len: 4,
            hide_row_len: 1,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_is_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::Is,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 1,
            hide_row_len: 4,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::Contains,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 3,
            hide_row_len: 2,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_start_with_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::StartsWith,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 2,
            hide_row_len: 3,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_ends_with_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterCondition::EndsWith,
            content: "A".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_delete_test() {
    let mut test = GridFilterTest::new().await;
    let field_rev = test.get_field_rev(FieldType::RichText).clone();
    let text_filter = TextFilterPB {
        condition: TextFilterCondition::TextIsEmpty,
        content: "".to_string(),
    };
    let payload = CreateFilterPayloadPB::new(&field_rev, text_filter);
    let scripts = vec![
        InsertFilter { payload },
        AssertFilterCount { count: 1 },
        AssertNumberOfVisibleRows { expected: 1 },
    ];
    test.run_scripts(scripts).await;

    let filter = test.grid_filters().await.pop().unwrap();
    test.run_scripts(vec![
        DeleteFilter {
            filter_id: filter.id,
            filter_type: FilterType::from(&field_rev),
        },
        AssertFilterCount { count: 0 },
        AssertNumberOfVisibleRows { expected: 5 },
    ])
    .await;
}
