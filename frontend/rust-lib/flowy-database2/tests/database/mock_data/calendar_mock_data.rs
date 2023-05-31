use crate::database::database_editor::TestRowBuilder;
use collab_database::database::{gen_database_id, gen_database_view_id, DatabaseData};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting, LayoutSettings};

use flowy_database2::entities::FieldType;
use flowy_database2::services::field::{FieldBuilder, MultiSelectTypeOption};
use flowy_database2::services::setting::CalendarLayoutSetting;
use strum::IntoEnumIterator;

// Calendar unit test mock data
pub fn make_test_calendar() -> DatabaseData {
  let mut fields = vec![];
  let mut rows = vec![];
  // text
  let text_field = FieldBuilder::from_field_type(FieldType::RichText)
    .name("Name")
    .visibility(true)
    .primary(true)
    .build();
  fields.push(text_field);

  // date
  let date_field = FieldBuilder::from_field_type(FieldType::DateTime)
    .name("Date")
    .visibility(true)
    .build();

  let date_field_id = date_field.id.clone();
  fields.push(date_field);

  // multi select

  let type_option = MultiSelectTypeOption::default();
  let multi_select_field = FieldBuilder::new(FieldType::MultiSelect, type_option)
    .name("Tags")
    .visibility(true)
    .build();
  fields.push(multi_select_field);

  let calendar_setting: LayoutSetting = CalendarLayoutSetting::new(date_field_id).into();

  for i in 0..5 {
    let mut row_builder = TestRowBuilder::new(i.into(), &fields);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::DateTime => {
              row_builder.insert_date_cell("1678090778", None, None, &field_type)
            },
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("B"),
            FieldType::DateTime => {
              row_builder.insert_date_cell("1677917978", None, None, &field_type)
            },
            _ => "".to_owned(),
          };
        }
      },
      2 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("C"),
            FieldType::DateTime => {
              row_builder.insert_date_cell("1679213978", None, None, &field_type)
            },
            _ => "".to_owned(),
          };
        }
      },
      3 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("D"),
            FieldType::DateTime => {
              row_builder.insert_date_cell("1678695578", None, None, &field_type)
            },
            _ => "".to_owned(),
          };
        }
      },
      4 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("E"),
            FieldType::DateTime => {
              row_builder.insert_date_cell("1678695578", None, None, &field_type)
            },
            _ => "".to_owned(),
          };
        }
      },
      _ => {},
    }

    let row = row_builder.build();
    rows.push(row);
  }
  let mut layout_settings = LayoutSettings::new();
  layout_settings.insert(DatabaseLayout::Calendar, calendar_setting);

  let view = DatabaseView {
    id: gen_database_view_id(),
    database_id: gen_database_id(),
    name: "".to_string(),
    layout: DatabaseLayout::Calendar,
    layout_settings,
    filters: vec![],
    group_settings: vec![],
    sorts: vec![],
    row_orders: vec![],
    field_orders: vec![],
    created_at: 0,
    modified_at: 0,
  };

  DatabaseData { view, fields, rows }
}
