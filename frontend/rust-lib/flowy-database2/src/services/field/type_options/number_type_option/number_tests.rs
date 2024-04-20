#[cfg(test)]
mod tests {

  use crate::services::cell::CellDataDecoder;
  use crate::services::field::NumberCellData;
  use crate::services::field::{NumberFormat, NumberTypeOption};

  /// Testing when the input is not a number.
  #[test]
  fn number_type_option_input_test() {
    let type_option = NumberTypeOption::default();

    // Input is empty String
    assert_number(&type_option, "", "");
    assert_number(&type_option, "abc", "");
    assert_number(&type_option, "-123", "-123");
    assert_number(&type_option, "abc-123", "-123");
    assert_number(&type_option, "+123", "123");
    assert_number(&type_option, "0.2", "0.2");
    assert_number(&type_option, "-0.2", "-0.2");
    assert_number(&type_option, "-$0.2", "0.2");
    assert_number(&type_option, ".2", "0.2");
  }

  #[test]
  fn dollar_type_option_test() {
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;

    assert_number(&type_option, "", "");
    assert_number(&type_option, "abc", "");
    assert_number(&type_option, "-123", "-$123");
    assert_number(&type_option, "+123", "$123");
    assert_number(&type_option, "0.2", "$0.2");
    assert_number(&type_option, "-0.2", "-$0.2");
    assert_number(&type_option, "-$0.2", "-$0.2");
    assert_number(&type_option, "-€0.2", "-$0.2");
    assert_number(&type_option, ".2", "$0.2");
  }

  #[test]
  fn dollar_type_option_test2() {
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;

    assert_number(&type_option, "99999999999", "$99,999,999,999");
    assert_number(&type_option, "$99,999,999,999", "$99,999,999,999");
  }
  #[test]
  fn other_symbol_to_dollar_type_option_test() {
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::USD;

    assert_number(&type_option, "€0.2", "$0.2");
    assert_number(&type_option, "-€0.2", "-$0.2");
    assert_number(&type_option, "-CN¥0.2", "-$0.2");
    assert_number(&type_option, "CN¥0.2", "$0.2");
    assert_number(&type_option, "0.2", "$0.2");
  }

  #[test]
  fn euro_type_option_test() {
    let mut type_option = NumberTypeOption::new();
    type_option.format = NumberFormat::EUR;

    assert_number(&type_option, "0.2", "€0,2");
    assert_number(&type_option, "1000", "€1.000");
    assert_number(&type_option, "1234.56", "€1.234,56");
  }

  fn assert_number(type_option: &NumberTypeOption, input_str: &str, expected_str: &str) {
    assert_eq!(
      type_option
        .decode_cell(&NumberCellData(input_str.to_owned()).into(),)
        .unwrap()
        .to_string(),
      expected_str.to_owned()
    );
  }
}
