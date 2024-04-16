#[cfg(test)]
mod tests {
  use collab_database::fields::Field;

  use crate::entities::FieldType;
  use crate::services::cell::CellDataChangeset;
  use crate::services::field::FieldBuilder;
  use crate::services::field::URLTypeOption;

  #[test]
  fn url_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "https://www.appflowy.io",
      "https://www.appflowy.io",
      &field,
    );
    assert_url(&type_option, "123", "123", &field);
    assert_url(&type_option, "", "", &field);
  }

  fn assert_url(type_option: &URLTypeOption, input_str: &str, expected_url: &str, _field: &Field) {
    let decode_cell_data = type_option
      .apply_changeset(input_str.to_owned(), None)
      .unwrap()
      .1;
    assert_eq!(expected_url.to_owned(), decode_cell_data.data);
  }
}
