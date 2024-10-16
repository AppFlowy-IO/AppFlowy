use crate::database::pre_fill_cell_test::script::DatabasePreFillRowCellTest;
use collab_database::fields::select_type_option::SELECTION_IDS_SEPARATOR;
use flowy_database2::entities::{
  CheckboxFilterConditionPB, CheckboxFilterPB, DateFilterConditionPB, DateFilterPB, FieldType,
  FilterDataPB, SelectOptionFilterConditionPB, SelectOptionFilterPB, TextFilterConditionPB,
  TextFilterPB,
};

#[tokio::test]
async fn according_to_text_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .insert_filter(FilterDataPB {
      field_id: text_field.id.clone(),
      field_type: FieldType::RichText,
      data: TextFilterPB {
        condition: TextFilterConditionPB::TextContains,
        content: "sample".to_string(),
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.create_empty_row().await;
  test.wait(100).await;

  test
    .assert_cell_existence(text_field.id.clone(), test.rows.len() - 1, true)
    .await;
  test
    .assert_cell_content(text_field.id, test.rows.len() - 1, "sample".to_string())
    .await;
}

#[tokio::test]
async fn according_to_empty_text_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .insert_filter(FilterDataPB {
      field_id: text_field.id.clone(),
      field_type: FieldType::RichText,
      data: TextFilterPB {
        condition: TextFilterConditionPB::TextContains,
        content: "".to_string(),
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.create_empty_row().await;
  test.wait(100).await;

  test
    .assert_cell_existence(text_field.id.clone(), test.rows.len() - 1, false)
    .await;
}

#[tokio::test]
async fn according_to_text_is_not_empty_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: text_field.id.clone(),
      field_type: FieldType::RichText,
      data: TextFilterPB {
        condition: TextFilterConditionPB::TextIsNotEmpty,
        content: "".to_string(),
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(6).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(6).await;
}

#[tokio::test]
async fn according_to_checkbox_is_unchecked_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: checkbox_field.id.clone(),
      field_type: FieldType::Checkbox,
      data: CheckboxFilterPB {
        condition: CheckboxFilterConditionPB::IsUnChecked,
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(4).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(5).await;

  test
    .assert_cell_existence(checkbox_field.id.clone(), 4, false)
    .await;
}

#[tokio::test]
async fn according_to_checkbox_is_checked_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: checkbox_field.id.clone(),
      field_type: FieldType::Checkbox,
      data: CheckboxFilterPB {
        condition: CheckboxFilterConditionPB::IsChecked,
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(3).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(4).await;

  test
    .assert_cell_existence(checkbox_field.id.clone(), 3, true)
    .await;
  test
    .assert_cell_content(checkbox_field.id, 3, "Yes".to_string())
    .await;
}

#[tokio::test]
async fn according_to_date_time_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let datetime_field = test.get_first_field(FieldType::DateTime).await;

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: datetime_field.id.clone(),
      field_type: FieldType::DateTime,
      data: DateFilterPB {
        condition: DateFilterConditionPB::DateStartsOn,
        timestamp: Some(1710510086),
        ..Default::default()
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(0).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(1).await;

  test
    .assert_cell_existence(datetime_field.id.clone(), 0, true)
    .await;
  test
    .assert_cell_content(datetime_field.id, 0, "2024/03/15".to_string())
    .await;
}

#[tokio::test]
async fn according_to_invalid_date_time_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let datetime_field = test.get_first_field(FieldType::DateTime).await;

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: datetime_field.id.clone(),
      field_type: FieldType::DateTime,
      data: DateFilterPB {
        condition: DateFilterConditionPB::DateStartsOn,
        timestamp: None,
        ..Default::default()
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(7).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(8).await;

  test
    .assert_cell_existence(datetime_field.id.clone(), test.rows.len() - 1, false)
    .await;
}

#[tokio::test]
async fn according_to_select_option_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let multi_select_field = test.get_first_field(FieldType::MultiSelect).await;
  let options = test
    .get_multi_select_type_option(&multi_select_field.id)
    .await;

  let filtering_options = [options[1].clone(), options[2].clone()];
  let ids = filtering_options
    .iter()
    .map(|option| option.id.clone())
    .collect();
  let stringified_expected = filtering_options
    .iter()
    .map(|option| option.name.clone())
    .collect::<Vec<_>>()
    .join(SELECTION_IDS_SEPARATOR);

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: multi_select_field.id.clone(),
      field_type: FieldType::MultiSelect,
      data: SelectOptionFilterPB {
        condition: SelectOptionFilterConditionPB::OptionIs,
        option_ids: ids,
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(1).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(2).await;

  test
    .assert_cell_existence(multi_select_field.id.clone(), 1, true)
    .await;
  test
    .assert_cell_content(multi_select_field.id, 1, stringified_expected)
    .await;
}

#[tokio::test]
async fn according_to_select_option_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let multi_select_field = test.get_first_field(FieldType::MultiSelect).await;
  let options = test
    .get_multi_select_type_option(&multi_select_field.id)
    .await;

  let filtering_options = [options[1].clone(), options[2].clone()];
  let ids = filtering_options
    .iter()
    .map(|option| option.id.clone())
    .collect();
  let stringified_expected = filtering_options.first().unwrap().name.clone();

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: multi_select_field.id.clone(),
      field_type: FieldType::MultiSelect,
      data: SelectOptionFilterPB {
        condition: SelectOptionFilterConditionPB::OptionContains,
        option_ids: ids,
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(5).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(6).await;

  test
    .assert_cell_existence(multi_select_field.id.clone(), 5, true)
    .await;
  test
    .assert_cell_content(multi_select_field.id, 5, stringified_expected)
    .await;
}

#[tokio::test]
async fn according_to_select_option_is_not_empty_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let multi_select_field = test.get_first_field(FieldType::MultiSelect).await;
  let options = test
    .get_multi_select_type_option(&multi_select_field.id)
    .await;

  let stringified_expected = options.first().unwrap().name.clone();

  test.assert_row_count(7).await;

  test
    .insert_filter(FilterDataPB {
      field_id: multi_select_field.id.clone(),
      field_type: FieldType::MultiSelect,
      data: SelectOptionFilterPB {
        condition: SelectOptionFilterConditionPB::OptionIsNotEmpty,
        ..Default::default()
      }
      .try_into()
      .unwrap(),
    })
    .await;

  test.wait(100).await;
  test.assert_row_count(5).await;
  test.create_empty_row().await;
  test.wait(100).await;
  test.assert_row_count(6).await;

  test
    .assert_cell_existence(multi_select_field.id.clone(), 5, true)
    .await;
  test
    .assert_cell_content(multi_select_field.id, 5, stringified_expected)
    .await;
}
