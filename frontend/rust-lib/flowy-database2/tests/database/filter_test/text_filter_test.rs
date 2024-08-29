use flowy_database2::entities::{FieldType, TextFilterConditionPB, TextFilterPB};
use lib_infra::box_any::BoxAny;

use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::*;

#[tokio::test]
async fn grid_filter_text_is_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextIsEmpty,
        content: "".to_string(),
      }),
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
  let mut test = DatabaseFilterTest::new().await;
  // Only one row's text of the initial rows is ""
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextIsNotEmpty,
        content: "".to_string(),
      }),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 1,
      }),
    },
    AssertFilterCount { count: 1 },
  ];
  test.run_scripts(scripts).await;

  let filter = test.database_filters().await.pop().unwrap();
  test
    .run_scripts(vec![
      DeleteFilter {
        filter_id: filter.id,
        field_id: filter.data.unwrap().field_id,
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
  let mut test = DatabaseFilterTest::new().await;
  // Only one row's text of the initial rows is "A"
  let scripts = vec![CreateDataFilter {
    parent_filter_id: None,
    field_type: FieldType::RichText,
    data: BoxAny::new(TextFilterPB {
      condition: TextFilterConditionPB::TextIs,
      content: "A".to_string(),
    }),
    changed: Some(FilterRowChanged {
      showing_num_of_rows: 0,
      hiding_num_of_rows: 5,
    }),
  }];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![CreateDataFilter {
    parent_filter_id: None,
    field_type: FieldType::RichText,
    data: BoxAny::new(TextFilterPB {
      condition: TextFilterConditionPB::TextContains,
      content: "A".to_string(),
    }),
    changed: Some(FilterRowChanged {
      showing_num_of_rows: 0,
      hiding_num_of_rows: 2,
    }),
  }];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_contain_text_test2() {
  let mut test = DatabaseFilterTest::new().await;
  let row_detail = test.rows.clone();

  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextContains,
        content: "A".to_string(),
      }),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 2,
      }),
    },
    UpdateTextCell {
      row_id: row_detail[1].id.clone(),
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
  let mut test = DatabaseFilterTest::new().await;
  // None of the initial rows contains the text "AB"
  let scripts = vec![CreateDataFilter {
    parent_filter_id: None,
    field_type: FieldType::RichText,
    data: BoxAny::new(TextFilterPB {
      condition: TextFilterConditionPB::TextDoesNotContain,
      content: "AB".to_string(),
    }),
    changed: Some(FilterRowChanged {
      showing_num_of_rows: 0,
      hiding_num_of_rows: 0,
    }),
  }];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_start_with_text_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![CreateDataFilter {
    parent_filter_id: None,
    field_type: FieldType::RichText,
    data: BoxAny::new(TextFilterPB {
      condition: TextFilterConditionPB::TextStartsWith,
      content: "A".to_string(),
    }),
    changed: Some(FilterRowChanged {
      showing_num_of_rows: 0,
      hiding_num_of_rows: 3,
    }),
  }];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_ends_with_text_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextEndsWith,
        content: "A".to_string(),
      }),
      changed: None,
    },
    AssertNumberOfVisibleRows { expected: 2 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_text_filter_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextEndsWith,
        content: "A".to_string(),
      }),
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
      condition: TextFilterConditionPB::TextIs,
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
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      changed: None,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextIsEmpty,
        content: "".to_string(),
      }),
    },
    AssertFilterCount { count: 1 },
    AssertNumberOfVisibleRows { expected: 1 },
  ];
  test.run_scripts(scripts).await;

  let filter = test.database_filters().await.pop().unwrap();
  test
    .run_scripts(vec![
      DeleteFilter {
        filter_id: filter.id,
        field_id: filter.data.unwrap().field_id,
        changed: None,
      },
      AssertFilterCount { count: 0 },
      AssertNumberOfVisibleRows { expected: 7 },
    ])
    .await;
}

#[tokio::test]
async fn grid_filter_update_empty_text_cell_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row = test.rows.clone();
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::RichText,
      data: BoxAny::new(TextFilterPB {
        condition: TextFilterConditionPB::TextIsEmpty,
        content: "".to_string(),
      }),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 5,
      }),
    },
    AssertFilterCount { count: 1 },
    UpdateTextCell {
      row_id: row[0].id.clone(),
      text: "".to_string(),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 1,
        hiding_num_of_rows: 0,
      }),
    },
  ];
  test.run_scripts(scripts).await;
}
