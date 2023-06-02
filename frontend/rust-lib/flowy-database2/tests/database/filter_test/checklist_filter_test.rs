use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged};
use flowy_database2::entities::ChecklistFilterConditionPB;

#[tokio::test]
async fn grid_filter_checklist_is_incomplete_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 5;
  let row_count = test.rows.len();
  let scripts = vec![
    UpdateChecklistCell {
      row_id: test.rows[0].id.clone(),
      f: Box::new(|options| options.into_iter().map(|option| option.id).collect()),
    },
    CreateChecklistFilter {
      condition: ChecklistFilterConditionPB::IsIncomplete,
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_checklist_is_complete_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 1;
  let row_count = test.rows.len();
  let scripts = vec![
    UpdateChecklistCell {
      row_id: test.rows[0].id.clone(),
      f: Box::new(|options| options.into_iter().map(|option| option.id).collect()),
    },
    CreateChecklistFilter {
      condition: ChecklistFilterConditionPB::IsComplete,
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected },
  ];
  test.run_scripts(scripts).await;
}
