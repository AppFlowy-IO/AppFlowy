use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::*;
use flowy_grid::entities::{CreateGridFilterPayload, TextFilterCondition};
use flowy_grid_data_model::revision::FieldRevision;

#[tokio::test]
async fn grid_filter_create_test() {
    let mut test = GridFilterTest::new().await;
    let field_rev = test.text_field();
    let payload = CreateGridFilterPayload::new(field_rev, TextFilterCondition::TextIsEmpty, Some("abc".to_owned()));
    let scripts = vec![InsertGridTableFilter { payload }, AssertTableFilterCount { count: 1 }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
#[should_panic]
async fn grid_filter_invalid_condition_panic_test() {
    let mut test = GridFilterTest::new().await;
    let field_rev = test.text_field().clone();

    // 100 is not a valid condition, so this test should be panic.
    let payload = CreateGridFilterPayload::new(&field_rev, 100, Some("".to_owned()));
    let scripts = vec![InsertGridTableFilter { payload }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_delete_test() {
    let mut test = GridFilterTest::new().await;
    let field_rev = test.text_field().clone();
    let payload = create_filter(&field_rev, TextFilterCondition::TextIsEmpty, "abc");
    let scripts = vec![InsertGridTableFilter { payload }, AssertTableFilterCount { count: 1 }];
    test.run_scripts(scripts).await;

    let filter = test.grid_filters().await.pop().unwrap();
    test.run_scripts(vec![
        DeleteGridTableFilter {
            filter_id: filter.id,
            field_rev,
        },
        AssertTableFilterCount { count: 0 },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_get_rows_test() {}

fn create_filter(field_rev: &FieldRevision, condition: TextFilterCondition, s: &str) -> CreateGridFilterPayload {
    CreateGridFilterPayload::new(field_rev, condition, Some(s.to_owned()))
}
