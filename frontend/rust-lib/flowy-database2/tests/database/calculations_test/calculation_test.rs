use std::sync::Arc;

use crate::database::calculations_test::script::{CalculationScript::*, DatabaseCalculationTest};

use collab_database::fields::Field;
use flowy_database2::entities::{CalculationType, FieldType, UpdateCalculationChangesetPB};

#[tokio::test]
async fn calculations_test() {
  let mut test = DatabaseCalculationTest::new().await;

  let expected_sum = 25.00000;
  let expected_min = 1.00000;
  let expected_average = 5.00000;
  let expected_max = 14.00000;
  let expected_median = 3.00000;

  let view_id = &test.view_id;
  let number_fields = test
    .fields
    .clone()
    .into_iter()
    .filter(|field| field.field_type == FieldType::Number as i64)
    .collect::<Vec<Arc<Field>>>();
  let field_id = &number_fields.first().unwrap().id;

  let calculation_id = "calc_id".to_owned();
  let scripts = vec![
    // Insert Sum calculation first time
    InsertCalculation {
      payload: UpdateCalculationChangesetPB {
        view_id: view_id.to_owned(),
        field_id: field_id.to_owned(),
        calculation_id: Some(calculation_id.clone()),
        calculation_type: CalculationType::Sum,
      },
    },
    AssertCalculationValue {
      expected: expected_sum,
    },
    InsertCalculation {
      payload: UpdateCalculationChangesetPB {
        view_id: view_id.to_owned(),
        field_id: field_id.to_owned(),
        calculation_id: Some(calculation_id.clone()),
        calculation_type: CalculationType::Min,
      },
    },
    AssertCalculationValue {
      expected: expected_min,
    },
    InsertCalculation {
      payload: UpdateCalculationChangesetPB {
        view_id: view_id.to_owned(),
        field_id: field_id.to_owned(),
        calculation_id: Some(calculation_id.clone()),
        calculation_type: CalculationType::Average,
      },
    },
    AssertCalculationValue {
      expected: expected_average,
    },
    InsertCalculation {
      payload: UpdateCalculationChangesetPB {
        view_id: view_id.to_owned(),
        field_id: field_id.to_owned(),
        calculation_id: Some(calculation_id.clone()),
        calculation_type: CalculationType::Max,
      },
    },
    AssertCalculationValue {
      expected: expected_max,
    },
    InsertCalculation {
      payload: UpdateCalculationChangesetPB {
        view_id: view_id.to_owned(),
        field_id: field_id.to_owned(),
        calculation_id: Some(calculation_id),
        calculation_type: CalculationType::Median,
      },
    },
    AssertCalculationValue {
      expected: expected_median,
    },
  ];
  test.run_scripts(scripts).await;
}
