#[cfg(test)]
mod tests {
  use collab_database::fields::Field;

  use crate::entities::FieldType;
  use crate::services::cell::CellDataDecoder;
  use crate::services::cell::FromCellString;
  use crate::services::field::type_options::checkbox_type_option::*;
  use crate::services::field::FieldBuilder;

  #[test]
  fn checkout_box_description_test() {
    let type_option = CheckboxTypeOption::default();
    let field_type = FieldType::Checkbox;
    let field_rev = FieldBuilder::from_field_type(field_type).build();

    // the checkout value will be checked if the value is "1", "true" or "yes"
    assert_checkbox(&type_option, "1", CHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "true", CHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "TRUE", CHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "yes", CHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "YES", CHECK, &field_type, &field_rev);

    // the checkout value will be uncheck if the value is "false" or "No"
    assert_checkbox(&type_option, "false", UNCHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "No", UNCHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "NO", UNCHECK, &field_type, &field_rev);
    assert_checkbox(&type_option, "0", UNCHECK, &field_type, &field_rev);

    // the checkout value will be empty if the value is letters or empty string
    assert_checkbox(&type_option, "abc", "", &field_type, &field_rev);
    assert_checkbox(&type_option, "", "", &field_type, &field_rev);
  }

  fn assert_checkbox(
    type_option: &CheckboxTypeOption,
    input_str: &str,
    expected_str: &str,
    field_type: &FieldType,
    field: &Field,
  ) {
    assert_eq!(
      type_option
        .decode_cell(
          &CheckboxCellData::from_cell_str(input_str).unwrap().into(),
          field_type,
          field
        )
        .unwrap()
        .to_string(),
      expected_str.to_owned()
    );
  }
}
