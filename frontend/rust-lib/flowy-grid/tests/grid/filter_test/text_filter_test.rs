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
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 5,
            }),
        },
        AssertFilterCount { count: 1 },
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
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 1,
            }),
        },
        AssertFilterCount { count: 1 },
    ];
    test.run_scripts(scripts).await;

    let filter = test.grid_filters().await.pop().unwrap();
    let field_rev = test.get_first_field_rev(FieldType::RichText).clone();
    test.run_scripts(vec![
        DeleteFilter {
            filter_id: filter.id,
            filter_type: FilterType::from(&field_rev),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 1,
                hiding_num_of_rows: 0,
            }),
        },
        AssertFilterCount { count: 0 },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_is_text_test() {
    let mut test = GridFilterTest::new().await;
    // Only one row's text of the initial rows is "A"
    let scripts = vec![CreateTextFilter {
        condition: TextFilterConditionPB::Is,
        content: "A".to_string(),
        changed: Some(FilterRowChanged {
            showing_num_of_rows: 0,
            hiding_num_of_rows: 5,
        }),
    }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![CreateTextFilter {
        condition: TextFilterConditionPB::Contains,
        content: "A".to_string(),
        changed: Some(FilterRowChanged {
            showing_num_of_rows: 0,
            hiding_num_of_rows: 2,
        }),
    }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test2() {
    let mut test = GridFilterTest::new().await;
    let row_revs = test.row_revs.clone();

    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::Contains,
            content: "A".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 2,
            }),
        },
        UpdateTextCell {
            row_id: row_revs[1].id.clone(),
            text: "ABC".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 1,
                hiding_num_of_rows: 0,
            }),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_does_not_contain_text_test() {
    let mut test = GridFilterTest::new().await;
    // None of the initial rows contains the text "AB"
    let scripts = vec![CreateTextFilter {
        condition: TextFilterConditionPB::DoesNotContain,
        content: "AB".to_string(),
        changed: Some(FilterRowChanged {
            showing_num_of_rows: 0,
            hiding_num_of_rows: 0,
        }),
    }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_start_with_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![CreateTextFilter {
        condition: TextFilterConditionPB::StartsWith,
        content: "A".to_string(),
        changed: Some(FilterRowChanged {
            showing_num_of_rows: 0,
            hiding_num_of_rows: 3,
        }),
    }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_ends_with_text_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::EndsWith,
            content: "A".to_string(),
            changed: None,
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
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 4,
            }),
        },
        AssertNumberOfVisibleRows { expected: 2 },
        AssertFilterCount { count: 1 },
    ];
    test.run_scripts(scripts).await;

    // Update the filter
    let filter = test.get_all_filters().await.pop().unwrap();
    let scripts = vec![
        UpdateTextFilter {
            filter,
            condition: TextFilterConditionPB::Is,
            content: "A".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 1,
            }),
        },
        AssertNumberOfVisibleRows { expected: 1 },
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
            changed: None,
        },
        AssertFilterCount { count: 0 },
        AssertNumberOfVisibleRows { expected: 6 },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_update_empty_text_cell_test() {
    let mut test = GridFilterTest::new().await;
    let row_revs = test.row_revs.clone();
    let scripts = vec![
        CreateTextFilter {
            condition: TextFilterConditionPB::TextIsEmpty,
            content: "".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: 5,
            }),
        },
        AssertFilterCount { count: 1 },
        UpdateTextCell {
            row_id: row_revs[0].id.clone(),
            text: "".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 1,
                hiding_num_of_rows: 0,
            }),
        },
    ];
    test.run_scripts(scripts).await;
}
