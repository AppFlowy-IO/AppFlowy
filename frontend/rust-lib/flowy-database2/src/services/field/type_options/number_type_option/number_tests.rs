#[cfg(test)]
mod tests {
  use collab_database::fields::Field;

  use crate::entities::FieldType;
  use crate::services::cell::CellDataDecoder;
  use crate::services::field::{FieldBuilder, NumberCellData};
  use crate::services::field::{NumberFormat, NumberTypeOption};

  /// Testing when the input is not a number.
  #[test]
  fn number_type_option_input_test() {
    let type_option = NumberTypeOption::default();
    let field_type = FieldType::Number;
    let field = FieldBuilder::from_field_type(field_type.clone()).build();

    // Input is empty String
    assert_number(&type_option, "", "", &field_type, &field);
    assert_number(&type_option, "abc", "", &field_type, &field);
    assert_number(&type_option, "-123", "-123", &field_type, &field);
    assert_number(&type_option, "abc-123", "-123", &field_type, &field);
    assert_number(&type_option, "+123", "123", &field_type, &field);
    assert_number(&type_option, "0.2", "0.2", &field_type, &field);
    assert_number(&type_option, "-0.2", "-0.2", &field_type, &field);
    assert_number(&type_option, "-$0.2", "0.2", &field_type, &field);
    assert_number(&type_option, ".2", "0.2", &field_type, &field);
  }

  #[test]
  fn dollar_type_option_test() {
    let field_type = FieldType::Number;
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;
    let field = FieldBuilder::new(field_type.clone(), type_option.clone()).build();

    assert_number(&type_option, "", "", &field_type, &field);
    assert_number(&type_option, "abc", "", &field_type, &field);
    assert_number(&type_option, "-123", "-$123", &field_type, &field);
    assert_number(&type_option, "+123", "$123", &field_type, &field);
    assert_number(&type_option, "0.2", "$0.2", &field_type, &field);
    assert_number(&type_option, "-0.2", "-$0.2", &field_type, &field);
    assert_number(&type_option, "-$0.2", "-$0.2", &field_type, &field);
    assert_number(&type_option, "-€0.2", "-$0.2", &field_type, &field);
    assert_number(&type_option, ".2", "$0.2", &field_type, &field);
  }

  #[test]
  fn dollar_type_option_test2() {
    let field_type = FieldType::Number;
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;
    let field = FieldBuilder::new(field_type.clone(), type_option.clone()).build();

    assert_number(
      &type_option,
      "99999999999",
      "$99,999,999,999",
      &field_type,
      &field,
    );
    assert_number(
      &type_option,
      "$99,999,999,999",
      "$99,999,999,999",
      &field_type,
      &field,
    );
  }
  #[test]
  fn other_symbol_to_dollar_type_option_test() {
    let field_type = FieldType::Number;
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;
    let field = FieldBuilder::new(field_type.clone(), type_option.clone()).build();

    assert_number(&type_option, "€0.2", "$0.2", &field_type, &field);
    assert_number(&type_option, "-€0.2", "-$0.2", &field_type, &field);
    assert_number(&type_option, "-CN¥0.2", "-$0.2", &field_type, &field);
    assert_number(&type_option, "CN¥0.2", "$0.2", &field_type, &field);
    assert_number(&type_option, "0.2", "$0.2", &field_type, &field);
  }

  #[test]
  fn euro_type_option_test() {
    let field_type = FieldType::Number;
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::EUR;
    let field = FieldBuilder::new(field_type.clone(), type_option.clone()).build();

    assert_number(&type_option, "0.2", "€0,2", &field_type, &field);
    assert_number(&type_option, "1000", "€1.000", &field_type, &field);
    assert_number(&type_option, "1234.56", "€1.234,56", &field_type, &field);
  }

  fn assert_number(
    type_option: &NumberTypeOption,
    input_str: &str,
    expected_str: &str,
    field_type: &FieldType,
    field: &Field,
  ) {
    assert_eq!(
      type_option
        .decode_cell(
          &NumberCellData(input_str.to_owned()).into(),
          field_type,
          field
        )
        .unwrap()
        .to_string(),
      expected_str.to_owned()
    );
  }
}
