// #![allow(clippy::all)]
// #![allow(dead_code)]
// #![allow(unused_imports)]
use crate::database::block_test::util::DatabaseRowTestBuilder;
use crate::database::mock_data::{
  COMPLETED, FACEBOOK, FIRST_THING, GOOGLE, PAUSED, PLANNED, SECOND_THING, THIRD_THING, TWITTER,
};

use flowy_client_sync::client_database::DatabaseBuilder;
use flowy_database::entities::*;

use flowy_database::services::field::SelectOptionPB;
use flowy_database::services::field::*;

use database_model::*;

use strum::IntoEnumIterator;

pub fn make_test_grid() -> BuildDatabaseContext {
  let mut database_builder = DatabaseBuilder::new();
  // Iterate through the FieldType to create the corresponding Field.
  for field_type in FieldType::iter() {
    let field_type: FieldType = field_type;

    // The
    match field_type {
      FieldType::RichText => {
        let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
          .name("Name")
          .visibility(true)
          .primary(true)
          .build();
        database_builder.add_field(text_field);
      },
      FieldType::Number => {
        // Number
        let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
        let number_field = FieldBuilder::new(number)
          .name("Price")
          .visibility(true)
          .build();
        database_builder.add_field(number_field);
      },
      FieldType::DateTime => {
        // Date
        let date = DateTypeOptionBuilder::default()
          .date_format(DateFormat::US)
          .time_format(TimeFormat::TwentyFourHour);
        let date_field = FieldBuilder::new(date)
          .name("Time")
          .visibility(true)
          .build();
        database_builder.add_field(date_field);
      },
      FieldType::SingleSelect => {
        // Single Select
        let single_select = SingleSelectTypeOptionBuilder::default()
          .add_option(SelectOptionPB::new(COMPLETED))
          .add_option(SelectOptionPB::new(PLANNED))
          .add_option(SelectOptionPB::new(PAUSED));
        let single_select_field = FieldBuilder::new(single_select)
          .name("Status")
          .visibility(true)
          .build();
        database_builder.add_field(single_select_field);
      },
      FieldType::MultiSelect => {
        // MultiSelect
        let multi_select = MultiSelectTypeOptionBuilder::default()
          .add_option(SelectOptionPB::new(GOOGLE))
          .add_option(SelectOptionPB::new(FACEBOOK))
          .add_option(SelectOptionPB::new(TWITTER));
        let multi_select_field = FieldBuilder::new(multi_select)
          .name("Platform")
          .visibility(true)
          .build();
        database_builder.add_field(multi_select_field);
      },
      FieldType::Checkbox => {
        // Checkbox
        let checkbox = CheckboxTypeOptionBuilder::default();
        let checkbox_field = FieldBuilder::new(checkbox)
          .name("is urgent")
          .visibility(true)
          .build();
        database_builder.add_field(checkbox_field);
      },
      FieldType::URL => {
        // URL
        let url = URLTypeOptionBuilder::default();
        let url_field = FieldBuilder::new(url).name("link").visibility(true).build();
        database_builder.add_field(url_field);
      },
      FieldType::Checklist => {
        let checklist = ChecklistTypeOptionBuilder::default()
          .add_option(SelectOptionPB::new(FIRST_THING))
          .add_option(SelectOptionPB::new(SECOND_THING))
          .add_option(SelectOptionPB::new(THIRD_THING));
        let checklist_field = FieldBuilder::new(checklist)
          .name("TODO")
          .visibility(true)
          .build();
        database_builder.add_field(checklist_field);
      },
    }
  }

  for i in 0..6 {
    let block_id = database_builder.block_id().to_owned();
    let field_revs = database_builder.field_revs().clone();
    let mut row_builder = DatabaseRowTestBuilder::new(block_id, field_revs);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::Number => row_builder.insert_number_cell("1"),
            FieldType::DateTime => row_builder.insert_date_cell("1647251762"),
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(0)]),
            FieldType::Checklist => row_builder.insert_checklist_cell(|options| options),
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            FieldType::URL => {
              row_builder.insert_url_cell("AppFlowy website - https://www.appflowy.io")
            },
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell(""),
            FieldType::Number => row_builder.insert_number_cell("2"),
            FieldType::DateTime => row_builder.insert_date_cell("1647251762"),
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(1)]),
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            _ => "".to_owned(),
          };
        }
      },
      2 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("C"),
            FieldType::Number => row_builder.insert_number_cell("3"),
            FieldType::DateTime => row_builder.insert_date_cell("1647251762"),
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::MultiSelect => {
              row_builder.insert_multi_select_cell(|mut options| vec![options.remove(1)])
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            _ => "".to_owned(),
          };
        }
      },
      3 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("DA"),
            FieldType::Number => row_builder.insert_number_cell("14"),
            FieldType::DateTime => row_builder.insert_date_cell("1668704685"),
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            _ => "".to_owned(),
          };
        }
      },
      4 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("AE"),
            FieldType::Number => row_builder.insert_number_cell(""),
            FieldType::DateTime => row_builder.insert_date_cell("1668359085"),
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },

            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            _ => "".to_owned(),
          };
        }
      },
      5 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("AE"),
            FieldType::Number => row_builder.insert_number_cell("5"),
            FieldType::DateTime => row_builder.insert_date_cell("1671938394"),
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
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
