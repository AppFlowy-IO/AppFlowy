// #![allow(clippy::all)]
// #![allow(dead_code)]
// #![allow(unused_imports)]

use collab_database::database::{gen_database_id, gen_database_view_id, gen_row_id, DatabaseData};
use collab_database::views::{DatabaseLayout, DatabaseView};
use strum::IntoEnumIterator;

use flowy_database2::entities::FieldType;
use flowy_database2::services::field::checklist_type_option::ChecklistTypeOption;
use flowy_database2::services::field::{
  DateFormat, DateTypeOption, FieldBuilder, MultiSelectTypeOption, SelectOption, SelectOptionColor,
  SingleSelectTypeOption, TimeFormat,
};

use crate::database::database_editor::TestRowBuilder;
use crate::database::mock_data::{COMPLETED, FACEBOOK, GOOGLE, PAUSED, PLANNED, TWITTER};

// Kanban board unit test mock data
pub fn make_test_board() -> DatabaseData {
  let mut fields = vec![];
  let mut rows = vec![];
  // Iterate through the FieldType to create the corresponding Field.
  for field_type in FieldType::iter() {
    match field_type {
      FieldType::RichText => {
        let text_field = FieldBuilder::from_field_type(field_type.clone())
          .name("Name")
          .visibility(true)
          .primary(true)
          .build();
        fields.push(text_field);
      },
      FieldType::Number => {
        // Number
        let number_field = FieldBuilder::from_field_type(field_type.clone())
          .name("Price")
          .visibility(true)
          .build();
        fields.push(number_field);
      },
      FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
        // Date
        let date_type_option = DateTypeOption {
          date_format: DateFormat::US,
          time_format: TimeFormat::TwentyFourHour,
          timezone_id: "Etc/UTC".to_owned(),
          field_type: field_type.clone(),
        };
        let name = match field_type {
          FieldType::DateTime => "Time",
          FieldType::LastEditedTime => "Updated At",
          FieldType::CreatedTime => "Created At",
          _ => "",
        };
        let date_field = FieldBuilder::new(field_type.clone(), date_type_option)
          .name(name)
          .visibility(true)
          .build();
        fields.push(date_field);
      },
      FieldType::SingleSelect => {
        // Single Select
        let option1 = SelectOption::with_color(COMPLETED, SelectOptionColor::Purple);
        let option2 = SelectOption::with_color(PLANNED, SelectOptionColor::Orange);
        let option3 = SelectOption::with_color(PAUSED, SelectOptionColor::Yellow);
        let mut single_select_type_option = SingleSelectTypeOption::default();
        single_select_type_option
          .options
          .extend(vec![option1, option2, option3]);
        let single_select_field = FieldBuilder::new(field_type.clone(), single_select_type_option)
          .name("Status")
          .visibility(true)
          .build();
        fields.push(single_select_field);
      },
      FieldType::MultiSelect => {
        // MultiSelect
        let option1 = SelectOption::with_color(GOOGLE, SelectOptionColor::Purple);
        let option2 = SelectOption::with_color(FACEBOOK, SelectOptionColor::Orange);
        let option3 = SelectOption::with_color(TWITTER, SelectOptionColor::Yellow);
        let mut type_option = MultiSelectTypeOption::default();
        type_option.options.extend(vec![option1, option2, option3]);
        let multi_select_field = FieldBuilder::new(field_type.clone(), type_option)
          .name("Platform")
          .visibility(true)
          .build();
        fields.push(multi_select_field);
      },
      FieldType::Checkbox => {
        // Checkbox
        let checkbox_field = FieldBuilder::from_field_type(field_type.clone())
          .name("is urgent")
          .visibility(true)
          .build();
        fields.push(checkbox_field);
      },
      FieldType::URL => {
        // URL
        let url = FieldBuilder::from_field_type(field_type.clone())
          .name("link")
          .visibility(true)
          .build();
        fields.push(url);
      },
      FieldType::Checklist => {
        // let option1 = SelectOption::with_color(FIRST_THING, SelectOptionColor::Purple);
        // let option2 = SelectOption::with_color(SECOND_THING, SelectOptionColor::Orange);
        // let option3 = SelectOption::with_color(THIRD_THING, SelectOptionColor::Yellow);
        let type_option = ChecklistTypeOption::default();
        // type_option.options.extend(vec![option1, option2, option3]);
        let checklist_field = FieldBuilder::new(field_type.clone(), type_option)
          .name("TODO")
          .visibility(true)
          .build();
        fields.push(checklist_field);
      },
    }
  }

  // We have many assumptions base on the number of the rows, so do not change the number of the loop.
  for i in 0..5 {
    let mut row_builder = TestRowBuilder::new(gen_row_id(), &fields);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::Number => row_builder.insert_number_cell("1"),
            // 1647251762 => Mar 14,2022
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              row_builder.insert_date_cell("1647251762", None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(0)]),
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            FieldType::URL => row_builder.insert_url_cell("https://appflowy.io"),
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("B"),
            FieldType::Number => row_builder.insert_number_cell("2"),
            // 1647251762 => Mar 14,2022
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              row_builder.insert_date_cell("1647251762", None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(0)]),
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
            // 1647251762 => Mar 14,2022
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              row_builder.insert_date_cell("1647251762", None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },
            FieldType::MultiSelect => {
              row_builder.insert_multi_select_cell(|mut options| vec![options.remove(0)])
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            FieldType::URL => {
              row_builder.insert_url_cell("https://github.com/AppFlowy-IO/AppFlowy")
            },
            _ => "".to_owned(),
          };
        }
      },
      3 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("DA"),
            FieldType::Number => row_builder.insert_number_cell("4"),
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              row_builder.insert_date_cell("1668704685", None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            FieldType::URL => row_builder.insert_url_cell("https://appflowy.io"),
            _ => "".to_owned(),
          };
        }
      },
      4 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("AE"),
            FieldType::Number => row_builder.insert_number_cell(""),
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              row_builder.insert_date_cell("1668359085", None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(2))
            },

            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            _ => "".to_owned(),
          };
        }
      },
      _ => {},
    }

    let row = row_builder.build();
    rows.push(row);
  }

  let view = DatabaseView {
    id: gen_database_view_id(),
    database_id: gen_database_id(),
    name: "".to_string(),
    layout: DatabaseLayout::Board,
    layout_settings: Default::default(),
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
