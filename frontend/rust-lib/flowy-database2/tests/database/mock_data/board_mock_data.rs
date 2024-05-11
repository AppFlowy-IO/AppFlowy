use collab_database::database::{gen_database_id, gen_database_view_id, gen_row_id, DatabaseData};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting, LayoutSettings};
use strum::IntoEnumIterator;

use flowy_database2::entities::FieldType;
use flowy_database2::services::field::checklist_type_option::ChecklistTypeOption;
use flowy_database2::services::field::{
  DateFormat, DateTypeOption, FieldBuilder, MultiSelectTypeOption, RelationTypeOption,
  SelectOption, SelectOptionColor, SingleSelectTypeOption, TimeFormat, TimestampTypeOption,
};
use flowy_database2::services::field_settings::default_field_settings_for_fields;
use flowy_database2::services::setting::BoardLayoutSetting;

use crate::database::database_editor::TestRowBuilder;
use crate::database::mock_data::{COMPLETED, FACEBOOK, GOOGLE, PAUSED, PLANNED, TWITTER};

// Kanban board unit test mock data
pub fn make_test_board() -> DatabaseData {
  let database_id = gen_database_id();
  let mut fields = vec![];
  let mut rows = vec![];
  // Iterate through the FieldType to create the corresponding Field.
  for field_type in FieldType::iter() {
    match field_type {
      FieldType::RichText => {
        let text_field = FieldBuilder::from_field_type(field_type)
          .name("Name")
          .primary(true)
          .build();
        fields.push(text_field);
      },
      FieldType::Number => {
        // Number
        let number_field = FieldBuilder::from_field_type(field_type)
          .name("Price")
          .build();
        fields.push(number_field);
      },
      FieldType::DateTime => {
        // Date
        let date_type_option = DateTypeOption {
          date_format: DateFormat::US,
          time_format: TimeFormat::TwentyFourHour,
          timezone_id: "Etc/UTC".to_owned(),
        };
        let name = "Time";
        let date_field = FieldBuilder::new(field_type, date_type_option)
          .name(name)
          .build();
        fields.push(date_field);
      },
      FieldType::LastEditedTime | FieldType::CreatedTime => {
        // LastEditedTime and CreatedTime
        let date_type_option = TimestampTypeOption {
          date_format: DateFormat::US,
          time_format: TimeFormat::TwentyFourHour,
          include_time: true,
          field_type,
        };
        let name = match field_type {
          FieldType::LastEditedTime => "Last Modified",
          FieldType::CreatedTime => "Created At",
          _ => "",
        };
        let date_field = FieldBuilder::new(field_type, date_type_option)
          .name(name)
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
        let single_select_field = FieldBuilder::new(field_type, single_select_type_option)
          .name("Status")
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
        let multi_select_field = FieldBuilder::new(field_type, type_option)
          .name("Platform")
          .build();
        fields.push(multi_select_field);
      },
      FieldType::Checkbox => {
        // Checkbox
        let checkbox_field = FieldBuilder::from_field_type(field_type)
          .name("is urgent")
          .build();
        fields.push(checkbox_field);
      },
      FieldType::URL => {
        // URL
        let url = FieldBuilder::from_field_type(field_type)
          .name("link")
          .build();
        fields.push(url);
      },
      FieldType::Checklist => {
        // let option1 = SelectOption::with_color(FIRST_THING, SelectOptionColor::Purple);
        // let option2 = SelectOption::with_color(SECOND_THING, SelectOptionColor::Orange);
        // let option3 = SelectOption::with_color(THIRD_THING, SelectOptionColor::Yellow);
        let type_option = ChecklistTypeOption;
        // type_option.options.extend(vec![option1, option2, option3]);
        let checklist_field = FieldBuilder::new(field_type, type_option)
          .name("TODO")
          .build();
        fields.push(checklist_field);
      },
      FieldType::Relation => {
        let type_option = RelationTypeOption {
          database_id: "".to_string(),
        };
        let relation_field = FieldBuilder::new(field_type, type_option)
          .name("Related")
          .build();
        fields.push(relation_field);
      },
      FieldType::Timer => {
        let timer_field = FieldBuilder::from_field_type(field_type.clone())
          .name("Estimated time")
          .visibility(true)
          .build();
        fields.push(timer_field);
      },
    }
  }

  let board_setting: LayoutSetting = BoardLayoutSetting::new().into();

  let field_settings = default_field_settings_for_fields(&fields, DatabaseLayout::Board);

  // We have many assumptions base on the number of the rows, so do not change the number of the loop.
  for i in 0..5 {
    let mut row_builder = TestRowBuilder::new(&database_id, gen_row_id(), &fields);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::Number => row_builder.insert_number_cell("1"),
            // 1647251762 => Mar 14,2022
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1668704685, None, None, &field_type)
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1668359085, None, None, &field_type)
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

  let mut layout_settings = LayoutSettings::new();
  layout_settings.insert(DatabaseLayout::Board, board_setting);

  let inline_view_id = gen_database_view_id();

  let view = DatabaseView {
    id: inline_view_id.clone(),
    database_id: database_id.clone(),
    name: "".to_string(),
    layout: DatabaseLayout::Board,
    layout_settings,
    filters: vec![],
    group_settings: vec![],
    sorts: vec![],
    row_orders: vec![],
    field_orders: vec![],
    created_at: 0,
    modified_at: 0,
    field_settings,
  };

  DatabaseData {
    database_id,
    inline_view_id,
    views: vec![view],
    fields,
    rows,
  }
}
