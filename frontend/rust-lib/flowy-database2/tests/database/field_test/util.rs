use collab_database::fields::Field;
use flowy_database2::entities::{CreateFieldParams, FieldType};
use flowy_database2::services::field::{
  type_option_to_pb, DateCellChangeset, DateFormat, DateTypeOption, FieldBuilder,
  RichTextTypeOption, SelectOption, SingleSelectTypeOption, TimeFormat,
};

pub fn create_text_field(grid_id: &str) -> (CreateFieldParams, Field) {
  let field_type = FieldType::RichText;
  let type_option = RichTextTypeOption::default();
  let text_field = FieldBuilder::new(field_type.clone(), type_option.clone())
    .name("Name")
    .visibility(true)
    .primary(true)
    .build();

  let type_option_data = type_option_to_pb(type_option.into(), &field_type).to_vec();
  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
  };
  (params, text_field)
}

pub fn create_single_select_field(grid_id: &str) -> (CreateFieldParams, Field) {
  let field_type = FieldType::SingleSelect;
  let mut type_option = SingleSelectTypeOption::default();
  type_option.options.push(SelectOption::new("Done"));
  type_option.options.push(SelectOption::new("Progress"));
  let single_select_field = FieldBuilder::new(field_type.clone(), type_option.clone())
    .name("Name")
    .visibility(true)
    .build();

  let type_option_data = type_option_to_pb(type_option.into(), &field_type).to_vec();
  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
  };
  (params, single_select_field)
}

pub fn create_date_field(grid_id: &str, field_type: FieldType) -> (CreateFieldParams, Field) {
  let date_type_option = DateTypeOption {
    date_format: DateFormat::US,
    time_format: TimeFormat::TwentyFourHour,
    timezone_id: "Etc/UTC".to_owned(),
    field_type: field_type.clone(),
  };

  let field: Field = match field_type {
    FieldType::DateTime => FieldBuilder::new(field_type.clone(), date_type_option.clone())
      .name("Date")
      .visibility(true)
      .build(),
    FieldType::LastEditedTime => FieldBuilder::new(field_type.clone(), date_type_option.clone())
      .name("Updated At")
      .visibility(true)
      .build(),
    FieldType::CreatedTime => FieldBuilder::new(field_type.clone(), date_type_option.clone())
      .name("Created At")
      .visibility(true)
      .build(),
    _ => panic!("Unsupported group field type"),
  };

  let type_option_data = type_option_to_pb(date_type_option.into(), &field_type).to_vec();

  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
  };
  (params, field)
}

//  The grid will contains all existing field types and there are three empty rows in this grid.

pub fn make_date_cell_string(s: &str) -> String {
  serde_json::to_string(&DateCellChangeset {
    date: Some(s.to_string()),
    time: None,
    include_time: Some(false),
  })
  .unwrap()
}
