use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::*;
use flowy_grid::entities::{AlterFilterPayloadPB, FieldType, TextFilterConditionPB, TextFilterPB};
use flowy_grid::services::filter::FilterType;

#[tokio::test]
async fn grid_filter_text_is_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::TextIsEmpty,
            content: "".to_string(),
        },
        AssertFilterCount { count: 1 },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 4,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_text_is_not_empty_test() {
    let mut test = GridFilterTest::new().await;
    // Only one row's text of the initial rows is ""
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::TextIsNotEmpty,
            content: "".to_string(),
        },
        AssertFilterCount { count: 1 },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 1,
        },
    ];
    test.run_scripts(scripts).await;

    let filter = test.grid_filters().await.pop().unwrap();
    let field_rev = test.get_first_field_rev(FieldType::RichText).clone();
    test.run_scripts(vec![
        DeleteFilter {
            filter_id: filter.id,
            filter_type: FilterType::from(&field_rev),
        },
        // AssertFilterChanged {
        //     visible_row_len: 1,
        //     hide_row_len: 0,
        // },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_is_text_test() {
    let mut test = GridFilterTest::new().await;
    // Only one row's text of the initial rows is "A"
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::Is,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 0,
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
            condition: TextFilterConditionPB::Contains,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 2,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test2() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::Contains,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 2,
        },
        UpdateTextCell {
            row_index: 1,
            text: "ABC".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 1,
            hide_row_len: 0,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_does_not_contain_text_test() {
    let mut test = GridFilterTest::new().await;
    // None of the initial rows contains the text "AB"
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::DoesNotContain,
            content: "AB".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 0,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_start_with_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::StartsWith,
            content: "A".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 0,
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
            condition: TextFilterConditionPB::EndsWith,
            content: "A".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_text_filter_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::EndsWith,
            content: "A".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;

    // Update the filter
    let filter = test.get_all_filters().await.pop().unwrap();
    let scripts = vec![
        UpdateTextFilter {
            filter,
            condition: TextFilterConditionPB::Is,
            content: "A".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 1 },
        AssertFilterCount { count: 1 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_delete_test() {
    let mut test = GridFilterTest::new().await;
    let field_rev = test.get_first_field_rev(FieldType::RichText).clone();
    let text_filter = TextFilterPB {
        condition: TextFilterConditionPB::TextIsEmpty,
        content: "".to_string(),
    };
    let payload = AlterFilterPayloadPB::new(&test.view_id(), &field_rev, text_filter);
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

#[tokio::test]
async fn grid_filter_update_empty_text_cell_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::TextIsEmpty,
            content: "".to_string(),
        },
        AssertFilterCount { count: 1 },
        AssertFilterChanged {
            visible_row_len: 0,
            hide_row_len: 4,
        },
        UpdateTextCell {
            row_index: 0,
            text: "".to_string(),
        },
        AssertFilterChanged {
            visible_row_len: 1,
            hide_row_len: 0,
        },
    ];
    test.run_scripts(scripts).await;
}
