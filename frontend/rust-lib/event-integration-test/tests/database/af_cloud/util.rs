use collab_database::database::{gen_database_id, gen_database_view_id, gen_row_id, DatabaseData};
use collab_database::entity::DatabaseView;
use collab_database::views::DatabaseLayout;
use event_integration_test::database_event::TestRowBuilder;

use collab_database::fields::number_type_option::{NumberFormat, NumberTypeOption};
use collab_database::fields::select_type_option::{
  SelectOption, SelectOptionColor, SingleSelectTypeOption,
};
use collab_database::fields::Field;
use collab_database::rows::Row;
use flowy_database2::entities::FieldType;
use flowy_database2::services::field::summary_type_option::summary::SummarizationTypeOption;
use flowy_database2::services::field::translate_type_option::translate::TranslateTypeOption;
use flowy_database2::services::field::FieldBuilder;
use flowy_database2::services::field_settings::default_field_settings_for_fields;
use strum::IntoEnumIterator;

#[allow(dead_code)]
pub fn make_test_summary_grid() -> DatabaseData {
  let database_id = gen_database_id();
  let fields = create_fields();
  let field_settings = default_field_settings_for_fields(&fields, DatabaseLayout::Grid);

  let single_select_field = fields
    .iter()
    .find(|field| field.field_type == FieldType::SingleSelect.value())
    .unwrap();

  let options = single_select_field
    .type_options
    .get(&FieldType::SingleSelect.to_string())
    .cloned()
    .map(|t| SingleSelectTypeOption::from(t).0.options)
    .unwrap();

  let rows = create_rows(&database_id, &fields, options);

  let inline_view_id = gen_database_view_id();
  let view = DatabaseView {
    database_id: database_id.clone(),
    id: inline_view_id.clone(),
    name: "".to_string(),
    layout: DatabaseLayout::Grid,
    field_settings,
    ..Default::default()
  };

  DatabaseData {
    database_id,
    inline_view_id,
    views: vec![view],
    fields,
    rows,
  }
}

#[allow(dead_code)]
fn create_fields() -> Vec<Field> {
  let mut fields = Vec::new();
  for field_type in FieldType::iter() {
    match field_type {
      FieldType::RichText => fields.push(create_text_field("Product Name", true)),
      FieldType::Number => fields.push(create_number_field("Price", NumberFormat::USD)),
      FieldType::SingleSelect => fields.push(create_single_select_field("Status")),
      FieldType::Summary => fields.push(create_summary_field("AI summary")),
      FieldType::Translate => fields.push(create_translate_field("AI Translate")),
      _ => {},
    }
  }
  fields
}

#[allow(dead_code)]
fn create_rows(database_id: &str, fields: &[Field], _options: Vec<SelectOption>) -> Vec<Row> {
  let mut rows = Vec::new();
  let fruits = ["Apple", "Pear", "Banana", "Orange"];
  for (i, fruit) in fruits.iter().enumerate() {
    let mut row_builder = TestRowBuilder::new(database_id, gen_row_id(), fields);
    row_builder.insert_text_cell(fruit);
    row_builder.insert_number_cell(match i {
      0 => "2.6",
      1 => "1.6",
      2 => "3.6",
      _ => "1.2",
    });
    row_builder.insert_single_select_cell(|mut options| options.remove(i % options.len()));
    rows.push(row_builder.build());
  }
  rows
}

#[allow(dead_code)]
fn create_text_field(name: &str, primary: bool) -> Field {
  FieldBuilder::from_field_type(FieldType::RichText)
    .name(name)
    .primary(primary)
    .build()
}

#[allow(dead_code)]
fn create_number_field(name: &str, format: NumberFormat) -> Field {
  let mut type_option = NumberTypeOption::default();
  type_option.set_format(format);
  FieldBuilder::new(FieldType::Number, type_option)
    .name(name)
    .build()
}

#[allow(dead_code)]
fn create_single_select_field(name: &str) -> Field {
  let options = vec![
    SelectOption::with_color("COMPLETED", SelectOptionColor::Purple),
    SelectOption::with_color("PLANNED", SelectOptionColor::Orange),
    SelectOption::with_color("PAUSED", SelectOptionColor::Yellow),
  ];
  let mut type_option = SingleSelectTypeOption::default();
  type_option.options.extend(options);
  FieldBuilder::new(FieldType::SingleSelect, type_option)
    .name(name)
    .build()
}

#[allow(dead_code)]
fn create_summary_field(name: &str) -> Field {
  let type_option = SummarizationTypeOption { auto_fill: false };
  FieldBuilder::new(FieldType::Summary, type_option)
    .name(name)
    .build()
}

#[allow(dead_code)]
fn create_translate_field(name: &str) -> Field {
  let type_option = TranslateTypeOption {
    auto_fill: false,
    language_type: 2,
  };
  FieldBuilder::new(FieldType::Translate, type_option)
    .name(name)
    .build()
}
