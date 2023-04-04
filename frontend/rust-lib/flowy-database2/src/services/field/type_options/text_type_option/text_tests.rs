#[cfg(test)]
mod tests {
  use crate::entities::FieldType;
  use crate::services::cell::stringify_cell_data;

  use crate::services::field::FieldBuilder;
  use crate::services::field::*;

  // Test parser the cell data which field's type is FieldType::Date to cell data
  // which field's type is FieldType::Text
  #[test]
  fn date_type_to_text_type() {
    let field_type = FieldType::DateTime;
    let field = FieldBuilder::from_field_type(&field_type).build();

    assert_eq!(
      stringify_cell_data(
        1647251762.to_string(),
        &FieldType::RichText,
        &field_type,
        &field
      ),
      "Mar 14,2022"
    );

    let data = DateCellData {
      timestamp: Some(1647251762),
      include_time: true,
    };

    assert_eq!(
      stringify_cell_data(data.to_string(), &FieldType::RichText, &field_type, &field),
      "Mar 14,2022"
    );
  }

  // Test parser the cell data which field's type is FieldType::SingleSelect to cell data
  // which field's type is FieldType::Text
  #[test]
  fn single_select_to_text_type() {
    let field_type = FieldType::SingleSelect;
    let done_option = SelectOption::new("Done");
    let option_id = done_option.id.clone();

    let single_select = SingleSelectTypeOption {
      options: vec![done_option.clone()],
      disable_color: false,
    };
    let field_rev = FieldBuilder::new(field_type, single_select).build();

    assert_eq!(
      stringify_cell_data(option_id, &FieldType::RichText, &field_type, &field_rev),
      done_option.name,
    );
  }
  /*
  - [Unit Test] Testing the switching from Multi-selection type to Text type
  - Tracking : https://github.com/AppFlowy-IO/AppFlowy/issues/1183
   */
  #[test]
  fn multiselect_to_text_type() {
    let field_type = FieldType::MultiSelect;

    let france = SelectOption::new("france");
    let france_option_id = france.id.clone();

    let argentina = SelectOption::new("argentina");
    let argentina_option_id = argentina.id.clone();

    let multi_select = MultiSelectTypeOption {
      options: vec![france.clone(), argentina.clone()],
      disable_color: false,
    };

    let field_rev = FieldBuilder::new(field_type, multi_select).build();

    assert_eq!(
      stringify_cell_data(
        format!("{},{}", france_option_id, argentina_option_id),
        &FieldType::RichText,
        &field_type,
        &field_rev
      ),
      format!("{},{}", france.name, argentina.name)
    );
  }
}
