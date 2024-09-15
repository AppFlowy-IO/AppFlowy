use bytes::Bytes;
use flowy_database2::entities::{
  CheckboxFilterConditionPB, CheckboxFilterPB, DateFilterConditionPB, DateFilterPB, FieldType,
  FilterDataPB, FilterPB, FilterType, NumberFilterConditionPB, NumberFilterPB,
};
use lib_infra::box_any::BoxAny;
use protobuf::ProtobufError;
use std::convert::TryInto;

use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged, FilterScript::*};

/// Create a single advanced filter:
///
/// 1. Add an OR filter
/// 2. Add a Checkbox and an AND filter to its children
/// 3. Add a DateTime and a Number filter to the AND filter's children
///
#[tokio::test]
async fn create_advanced_filter_test() {
  let mut test = DatabaseFilterTest::new().await;

  let create_checkbox_filter = || -> CheckboxFilterPB {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::IsChecked,
    }
  };

  let create_date_filter = || -> DateFilterPB {
    DateFilterPB {
      condition: DateFilterConditionPB::DateAfter,
      timestamp: Some(1651366800),
      ..Default::default()
    }
  };

  let create_number_filter = || -> NumberFilterPB {
    NumberFilterPB {
      condition: NumberFilterConditionPB::NumberIsNotEmpty,
      content: "".to_string(),
    }
  };

  let scripts = vec![
    CreateOrFilter {
      parent_filter_id: None,
      changed: None,
    },
    Wait { millisecond: 100 },
    AssertFilters {
      expected: vec![FilterPB {
        id: "".to_string(),
        filter_type: FilterType::Or,
        children: vec![],
        data: None,
      }],
    },
  ];
  test.run_scripts(scripts).await;
  // OR

  let or_filter = test.get_filter(FilterType::Or, None).await.unwrap();
  let checkbox_filter_bytes: Result<Bytes, ProtobufError> = create_checkbox_filter().try_into();
  let checkbox_filter_bytes = checkbox_filter_bytes.unwrap().to_vec();

  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: Some(or_filter.id.clone()),
      field_type: FieldType::Checkbox,
      data: BoxAny::new(create_checkbox_filter()),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 4,
      }),
    },
    CreateAndFilter {
      parent_filter_id: Some(or_filter.id),
      changed: None,
    },
    Wait { millisecond: 100 },
    AssertFilters {
      expected: vec![FilterPB {
        id: "".to_string(),
        filter_type: FilterType::Or,
        children: vec![
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::Data,
            children: vec![],
            data: Some(FilterDataPB {
              field_id: "".to_string(),
              field_type: FieldType::Checkbox,
              data: checkbox_filter_bytes.clone(),
            }),
          },
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::And,
            children: vec![],
            data: None,
          },
        ],
        data: None,
      }],
    },
    AssertNumberOfVisibleRows { expected: 3 },
  ];
  test.run_scripts(scripts).await;
  // IS_CHECK OR AND

  let and_filter = test.get_filter(FilterType::And, None).await.unwrap();

  let date_filter_bytes: Result<Bytes, ProtobufError> = create_date_filter().try_into();
  let date_filter_bytes = date_filter_bytes.unwrap().to_vec();
  let number_filter_bytes: Result<Bytes, ProtobufError> = create_number_filter().try_into();
  let number_filter_bytes = number_filter_bytes.unwrap().to_vec();

  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: Some(and_filter.id.clone()),
      field_type: FieldType::DateTime,
      data: BoxAny::new(create_date_filter()),
      changed: None,
    },
    CreateDataFilter {
      parent_filter_id: Some(and_filter.id),
      field_type: FieldType::Number,
      data: BoxAny::new(create_number_filter()),
      changed: None,
    },
    Wait { millisecond: 100 },
    AssertFilters {
      expected: vec![FilterPB {
        id: "".to_string(),
        filter_type: FilterType::Or,
        children: vec![
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::Data,
            children: vec![],
            data: Some(FilterDataPB {
              field_id: "".to_string(),
              field_type: FieldType::Checkbox,
              data: checkbox_filter_bytes,
            }),
          },
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::And,
            children: vec![
              FilterPB {
                id: "".to_string(),
                filter_type: FilterType::Data,
                children: vec![],
                data: Some(FilterDataPB {
                  field_id: "".to_string(),
                  field_type: FieldType::DateTime,
                  data: date_filter_bytes,
                }),
              },
              FilterPB {
                id: "".to_string(),
                filter_type: FilterType::Data,
                children: vec![],
                data: Some(FilterDataPB {
                  field_id: "".to_string(),
                  field_type: FieldType::Number,
                  data: number_filter_bytes,
                }),
              },
            ],
            data: None,
          },
        ],
        data: None,
      }],
    },
    AssertNumberOfVisibleRows { expected: 4 },
  ];
  test.run_scripts(scripts).await;
  // IS_CHECK OR (DATE > 1651366800 AND NUMBER NOT EMPTY)
}

/// Create the same advanced filter single advanced filter:
///
/// 1. Add an OR filter
/// 2. Add a Checkbox and a DateTime filter to its children
/// 3. Add a Number filter to the DateTime filter's children
///
#[tokio::test]
async fn create_advanced_filter_with_conversion_test() {
  let mut test = DatabaseFilterTest::new().await;

  let create_checkbox_filter = || -> CheckboxFilterPB {
    CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::IsChecked,
    }
  };

  let create_date_filter = || -> DateFilterPB {
    DateFilterPB {
      condition: DateFilterConditionPB::DateAfter,
      timestamp: Some(1651366800),
      ..Default::default()
    }
  };

  let create_number_filter = || -> NumberFilterPB {
    NumberFilterPB {
      condition: NumberFilterConditionPB::NumberIsNotEmpty,
      content: "".to_string(),
    }
  };

  let scripts = vec![CreateOrFilter {
    parent_filter_id: None,
    changed: None,
  }];
  test.run_scripts(scripts).await;
  // IS_CHECK OR DATE > 1651366800

  let or_filter = test.get_filter(FilterType::Or, None).await.unwrap();

  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: Some(or_filter.id.clone()),
      field_type: FieldType::Checkbox,
      data: BoxAny::new(create_checkbox_filter()),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 4,
      }),
    },
    CreateDataFilter {
      parent_filter_id: Some(or_filter.id.clone()),
      field_type: FieldType::DateTime,
      data: BoxAny::new(create_date_filter()),
      changed: None,
    },
  ];
  test.run_scripts(scripts).await;
  // OR

  let date_filter = test
    .get_filter(FilterType::Data, Some(FieldType::DateTime))
    .await
    .unwrap();

  let checkbox_filter_bytes: Result<Bytes, ProtobufError> = create_checkbox_filter().try_into();
  let checkbox_filter_bytes = checkbox_filter_bytes.unwrap().to_vec();
  let date_filter_bytes: Result<Bytes, ProtobufError> = create_date_filter().try_into();
  let date_filter_bytes = date_filter_bytes.unwrap().to_vec();
  let number_filter_bytes: Result<Bytes, ProtobufError> = create_number_filter().try_into();
  let number_filter_bytes = number_filter_bytes.unwrap().to_vec();

  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: Some(date_filter.id),
      field_type: FieldType::Number,
      data: BoxAny::new(create_number_filter()),
      changed: None,
    },
    Wait { millisecond: 100 },
    AssertFilters {
      expected: vec![FilterPB {
        id: "".to_string(),
        filter_type: FilterType::Or,
        children: vec![
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::Data,
            children: vec![],
            data: Some(FilterDataPB {
              field_id: "".to_string(),
              field_type: FieldType::Checkbox,
              data: checkbox_filter_bytes,
            }),
          },
          FilterPB {
            id: "".to_string(),
            filter_type: FilterType::And,
            children: vec![
              FilterPB {
                id: "".to_string(),
                filter_type: FilterType::Data,
                children: vec![],
                data: Some(FilterDataPB {
                  field_id: "".to_string(),
                  field_type: FieldType::DateTime,
                  data: date_filter_bytes,
                }),
              },
              FilterPB {
                id: "".to_string(),
                filter_type: FilterType::Data,
                children: vec![],
                data: Some(FilterDataPB {
                  field_id: "".to_string(),
                  field_type: FieldType::Number,
                  data: number_filter_bytes,
                }),
              },
            ],
            data: None,
          },
        ],
        data: None,
      }],
    },
    AssertNumberOfVisibleRows { expected: 4 },
  ];
  test.run_scripts(scripts).await;
  // IS_CHECK OR (DATE > 1651366800 AND NUMBER NOT EMPTY)
}
