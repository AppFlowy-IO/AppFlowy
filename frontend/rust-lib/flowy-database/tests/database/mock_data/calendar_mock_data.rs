use crate::database::block_test::util::DatabaseRowTestBuilder;
use database_model::{BuildDatabaseContext, CalendarLayoutSetting, LayoutRevision, LayoutSetting};
use flowy_client_sync::client_database::DatabaseBuilder;
use flowy_database::entities::FieldType;
use flowy_database::services::field::{
  DateTypeOptionBuilder, FieldBuilder, MultiSelectTypeOptionBuilder, RichTextTypeOptionBuilder,
};

use strum::IntoEnumIterator;

// Calendar unit test mock data
pub fn make_test_calendar() -> BuildDatabaseContext {
  let mut database_builder = DatabaseBuilder::new();
  // text
  let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
    .name("Title")
    .visibility(true)
    .primary(true)
    .build();
  let _text_field_id = text_field.id.clone();
  database_builder.add_field(text_field);

  // date
  let date_type_option = DateTypeOptionBuilder::default();
  let date_field = FieldBuilder::new(date_type_option)
    .name("Date")
    .visibility(true)
    .build();
  let date_field_id = date_field.id.clone();
  database_builder.add_field(date_field);

  // single select
  let multi_select_type_option = MultiSelectTypeOptionBuilder::default();
  let multi_select_field = FieldBuilder::new(multi_select_type_option)
    .name("Tags")
    .visibility(true)
    .build();
  database_builder.add_field(multi_select_field);

  let calendar_layout_setting = CalendarLayoutSetting::new(date_field_id);
  let mut layout_setting = LayoutSetting::new();
  let calendar_setting = serde_json::to_string(&calendar_layout_setting).unwrap();
  layout_setting.insert(LayoutRevision::Calendar, calendar_setting);
  database_builder.set_layout_setting(layout_setting);

  for i in 0..5 {
    let block_id = database_builder.block_id().to_owned();
    let field_revs = database_builder.field_revs().clone();
    let mut row_builder = DatabaseRowTestBuilder::new(block_id.clone(), field_revs);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::DateTime => row_builder.insert_date_cell("1678090778"),
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("B"),
            FieldType::DateTime => row_builder.insert_date_cell("1677917978"),
            _ => "".to_owned(),
          };
        }
      },
      2 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("C"),
            FieldType::DateTime => row_builder.insert_date_cell("1679213978"),
            _ => "".to_owned(),
          };
        }
      },
      3 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("D"),
            FieldType::DateTime => row_builder.insert_date_cell("1678695578"),
            _ => "".to_owned(),
          };
        }
      },
      4 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("E"),
            FieldType::DateTime => row_builder.insert_date_cell("1678695578"),
            _ => "".to_owned(),
          };
        }
      },
      _ => {},
    }

    let row_rev = row_builder.build();
    database_builder.add_row(row_rev);
  }

  database_builder.build()
}
