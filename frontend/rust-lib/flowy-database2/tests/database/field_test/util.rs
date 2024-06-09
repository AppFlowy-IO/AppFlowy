use collab_database::fields::Field;
use collab_database::views::OrderObjectPosition;

use flowy_database2::entities::{CreateFieldParams, FieldType};
use flowy_database2::services::field::{
  type_option_to_pb, DateFormat, DateTypeOption, FieldBuilder, RichTextTypeOption, SelectOption,
  SingleSelectTypeOption, TimeFormat, TimestampTypeOption,
};

pub fn create_text_field(grid_id: &str) -> (CreateFieldParams, Field) {
  let field_type = FieldType::RichText;
  let type_option = RichTextTypeOption::default();
  let text_field = FieldBuilder::new(field_type, type_option.clone())
    .name("Name")
    .primary(true)
    .build();

  let type_option_data = type_option_to_pb(type_option.into(), &field_type).to_vec();
  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
    field_name: None,
    position: OrderObjectPosition::default(),
  };
  (params, text_field)
}

pub fn create_single_select_field(grid_id: &str) -> (CreateFieldParams, Field) {
  let field_type = FieldType::SingleSelect;
  let mut type_option = SingleSelectTypeOption::default();
  type_option.options.push(SelectOption::new("Done"));
  type_option.options.push(SelectOption::new("Progress"));
  let single_select_field = FieldBuilder::new(field_type, type_option.clone())
    .name("Name")
    .build();

  let type_option_data = type_option_to_pb(type_option.into(), &field_type).to_vec();
  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
    field_name: None,
    position: OrderObjectPosition::default(),
  };
  (params, single_select_field)
}
#[allow(dead_code)]
pub fn create_date_field(grid_id: &str) -> (CreateFieldParams, Field) {
  let date_type_option = DateTypeOption {
    date_format: DateFormat::US,
    time_format: TimeFormat::TwentyFourHour,
    timezone_id: "Etc/UTC".to_owned(),
  };

  let field = FieldBuilder::new(FieldType::DateTime, date_type_option.clone())
    .name("Date")
    .build();

  let type_option_data = type_option_to_pb(date_type_option.into(), &FieldType::DateTime).to_vec();

  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type: FieldType::DateTime,
    type_option_data: Some(type_option_data),
    field_name: None,
    position: OrderObjectPosition::default(),
  };
  (params, field)
}

pub fn create_timestamp_field(grid_id: &str, field_type: FieldType) -> (CreateFieldParams, Field) {
  let timestamp_type_option = TimestampTypeOption {
    date_format: DateFormat::US,
    time_format: TimeFormat::TwentyFourHour,
    include_time: true,
    field_type,
  };

  let field: Field = match field_type {
    FieldType::LastEditedTime => FieldBuilder::new(field_type, timestamp_type_option.clone())
      .name("Updated At")
      .build(),
    FieldType::CreatedTime => FieldBuilder::new(field_type, timestamp_type_option.clone())
      .name("Created At")
      .build(),
    _ => panic!("Unsupported group field type"),
  };

  let type_option_data = type_option_to_pb(timestamp_type_option.into(), &field_type).to_vec();

  let params = CreateFieldParams {
    view_id: grid_id.to_owned(),
    field_type,
    type_option_data: Some(type_option_data),
    field_name: None,
    position: OrderObjectPosition::default(),
  };
  (params, field)
}
