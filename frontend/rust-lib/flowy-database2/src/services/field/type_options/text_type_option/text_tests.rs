#[cfg(test)]
mod tests {
  use crate::entities::FieldType;
  use crate::services::cell::{insert_select_option_cell, stringify_cell};
  use crate::services::field::FieldBuilder;
  use crate::services::field::*;
  use collab_database::fields::select_type_option::{SelectOption, SelectTypeOption};

  // Test parser the cell data which field's type is FieldType::Date to cell data
  // which field's type is FieldType::Text
  #[test]
  fn date_type_to_text_type() {
    let field_type = FieldType::DateTime;
    let field = FieldBuilder::new(field_type, DateTypeOption::test()).build();

    let data = DateCellData {
      timestamp: Some(1647251762),
      ..Default::default()
    };

    assert_eq!(stringify_cell(&(&data).into(), &field), "Mar 14, 2022");

    let data = DateCellData {
      timestamp: Some(1647251762),
      end_timestamp: None,
      include_time: true,
      is_range: false,
      reminder_id: String::new(),
    };

    assert_eq!(
      stringify_cell(&(&data).into(), &field),
      "Mar 14, 2022 09:56"
    );

    let data = DateCellData {
      timestamp: Some(1647251762),
      end_timestamp: Some(1648533809),
      include_time: true,
      is_range: false,
      reminder_id: String::new(),
    };

    assert_eq!(
      stringify_cell(&(&data).into(), &field),
      "Mar 14, 2022 09:56"
    );

    let data = DateCellData {
      timestamp: Some(1647251762),
      end_timestamp: Some(1648533809),
      include_time: true,
      is_range: true,
      reminder_id: String::new(),
    };

    assert_eq!(
      stringify_cell(&(&data).into(), &field),
      "Mar 14, 2022 09:56 → Mar 29, 2022 06:03"
    );
  }

  // Test parser the cell data which field's type is FieldType::SingleSelect to cell data
  // which field's type is FieldType::Text
  #[test]
  fn single_select_to_text_type() {
    let field_type = FieldType::SingleSelect;
    let done_option = SelectOption::new("Done");
    let option_id = done_option.id.clone();

    let single_select = SelectTypeOption {
      options: vec![done_option.clone()],
      disable_color: false,
    };
    let field = FieldBuilder::new(field_type, single_select).build();

    let cell = insert_select_option_cell(vec![option_id], &field);

    assert_eq!(stringify_cell(&cell, &field), done_option.name,);
  }

  #[test]
  fn multiselect_to_text_type() {
    let field_type = FieldType::MultiSelect;

    let france = SelectOption::new("france");
    let argentina = SelectOption::new("argentina");
    let multi_select = SelectTypeOption {
      options: vec![france.clone(), argentina.clone()],
      disable_color: false,
    };

    let france_option_id = france.id;
    let argentina_option_id = argentina.id;

    let field = FieldBuilder::new(field_type, multi_select).build();

    let cell = insert_select_option_cell(vec![france_option_id, argentina_option_id], &field);

    assert_eq!(
      stringify_cell(&cell, &field),
      format!("{},{}", france.name, argentina.name)
    );
  }
}
