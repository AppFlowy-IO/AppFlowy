#[cfg(test)]
mod tests {
  use collab_database::fields::Field;

  use crate::entities::FieldType;
  use crate::services::cell::CellDataChangeset;
  use crate::services::field::FieldBuilder;
  use crate::services::field::URLTypeOption;

  /// The expected_str will equal to the input string, but the expected_url will be empty if there's no
  /// http url in the input string.
  #[test]
  fn url_type_option_does_not_contain_url_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(&type_option, "123", "123", "", &field);
    assert_url(&type_option, "", "", "", &field);
  }

  /// The expected_str will equal to the input string, but the expected_url will not be empty
  /// if there's a http url in the input string.
  #[test]
  fn url_type_option_contains_url_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "AppFlowy website - https://www.appflowy.io",
      "AppFlowy website - https://www.appflowy.io",
      "https://www.appflowy.io/",
      &field,
    );

    assert_url(
      &type_option,
      "AppFlowy website appflowy.io",
      "AppFlowy website appflowy.io",
      "https://appflowy.io",
      &field,
    );
  }

  /// if there's a http url and some words following it in the input string.
  #[test]
  fn url_type_option_contains_url_with_string_after_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "AppFlowy website - https://www.appflowy.io welcome!",
      "AppFlowy website - https://www.appflowy.io welcome!",
      "https://www.appflowy.io/",
      &field,
    );

    assert_url(
      &type_option,
      "AppFlowy website appflowy.io welcome!",
      "AppFlowy website appflowy.io welcome!",
      "https://appflowy.io",
      &field,
    );
  }

  /// if there's a http url and special words following it in the input string.
  #[test]
  fn url_type_option_contains_url_with_special_string_after_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "AppFlowy website - https://www.appflowy.io!",
      "AppFlowy website - https://www.appflowy.io!",
      "https://www.appflowy.io/",
      &field,
    );

    assert_url(
      &type_option,
      "AppFlowy website appflowy.io!",
      "AppFlowy website appflowy.io!",
      "https://appflowy.io",
      &field,
    );
  }

  /// if there's a level4 url in the input string.
  #[test]
  fn level4_url_type_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "test - https://tester.testgroup.appflowy.io",
      "test - https://tester.testgroup.appflowy.io",
      "https://tester.testgroup.appflowy.io/",
      &field,
    );

    assert_url(
      &type_option,
      "test tester.testgroup.appflowy.io",
      "test tester.testgroup.appflowy.io",
      "https://tester.testgroup.appflowy.io",
      &field,
    );
  }

  /// urls with different top level domains.
  #[test]
  fn different_top_level_domains_test() {
    let type_option = URLTypeOption::default();
    let field_type = FieldType::URL;
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_url(
      &type_option,
      "appflowy - https://appflowy.com",
      "appflowy - https://appflowy.com",
      "https://appflowy.com/",
      &field,
    );

    assert_url(
      &type_option,
      "appflowy - https://appflowy.top",
      "appflowy - https://appflowy.top",
      "https://appflowy.top/",
      &field,
    );

    assert_url(
      &type_option,
      "appflowy - https://appflowy.net",
      "appflowy - https://appflowy.net",
      "https://appflowy.net/",
      &field,
    );

    assert_url(
      &type_option,
      "appflowy - https://appflowy.edu",
      "appflowy - https://appflowy.edu",
      "https://appflowy.edu/",
      &field,
    );
  }

  fn assert_url(
    type_option: &URLTypeOption,
    input_str: &str,
    expected_str: &str,
    expected_url: &str,
    _field: &Field,
  ) {
    let decode_cell_data = type_option
      .apply_changeset(input_str.to_owned(), None)
      .unwrap()
      .1;
    assert_eq!(expected_str.to_owned(), decode_cell_data.data);
    assert_eq!(expected_url.to_owned(), decode_cell_data.url);
  }
}
