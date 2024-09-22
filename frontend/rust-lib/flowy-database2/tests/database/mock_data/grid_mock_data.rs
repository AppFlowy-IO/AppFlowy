use collab_database::database::{gen_database_id, gen_database_view_id, gen_row_id, DatabaseData};
use collab_database::entity::DatabaseView;
use collab_database::fields::number_type_option::{NumberFormat, NumberTypeOption};
use collab_database::fields::select_type_option::{
  MultiSelectTypeOption, SelectOption, SelectOptionColor, SingleSelectTypeOption,
};
use collab_database::views::DatabaseLayout;
use strum::IntoEnumIterator;

use crate::database::mock_data::{COMPLETED, FACEBOOK, GOOGLE, PAUSED, PLANNED, TWITTER};
use event_integration_test::database_event::TestRowBuilder;
use flowy_database2::entities::FieldType;
use flowy_database2::services::field::summary_type_option::summary::SummarizationTypeOption;
use flowy_database2::services::field::translate_type_option::translate::TranslateTypeOption;
use flowy_database2::services::field::{
  ChecklistTypeOption, DateFormat, DateTypeOption, FieldBuilder, MediaTypeOption,
  RelationTypeOption, TimeFormat, TimeTypeOption, TimestampTypeOption,
};
use flowy_database2::services::field_settings::default_field_settings_for_fields;

pub fn make_test_grid() -> DatabaseData {
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
        let mut type_option = NumberTypeOption::default();
        type_option.set_format(NumberFormat::USD);

        let number_field = FieldBuilder::new(field_type, type_option)
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
        let timestamp_type_option = TimestampTypeOption {
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
        let timestamp_field = FieldBuilder::new(field_type, timestamp_type_option)
          .name(name)
          .build();
        fields.push(timestamp_field);
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
        let type_option = ChecklistTypeOption;
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
      FieldType::Summary => {
        let type_option = SummarizationTypeOption { auto_fill: false };
        let relation_field = FieldBuilder::new(field_type, type_option)
          .name("AI summary")
          .build();
        fields.push(relation_field);
      },
      FieldType::Time => {
        let type_option = TimeTypeOption;
        let time_field = FieldBuilder::new(field_type, type_option)
          .name("Estimated time")
          .build();
        fields.push(time_field);
      },
      FieldType::Translate => {
        let type_option = TranslateTypeOption {
          auto_fill: false,
          language_type: 0,
        };
        let translate_field = FieldBuilder::new(field_type, type_option)
          .name("AI translate")
          .build();
        fields.push(translate_field);
      },
      FieldType::Media => {
        let type_option = MediaTypeOption {
          files: vec![],
          hide_file_names: false,
        };

        let media_field = FieldBuilder::new(field_type, type_option)
          .name("Media")
          .build();
        fields.push(media_field);
      },
    }
  }

  let field_settings = default_field_settings_for_fields(&fields, DatabaseLayout::Grid);

  for i in 0..7 {
    let mut row_builder = TestRowBuilder::new(&database_id, gen_row_id(), &fields);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::Number => row_builder.insert_number_cell("1"),
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
            },
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(0)]),
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            FieldType::URL => {
              row_builder.insert_url_cell("AppFlowy website - https://www.appflowy.io")
            },
            FieldType::Checklist => {
              row_builder.insert_checklist_cell(vec![("First thing".to_string(), false)])
            },
            FieldType::Time => row_builder.insert_time_cell(75),
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell(""),
            FieldType::Number => row_builder.insert_number_cell("2"),
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
            },
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(0), options.remove(1)]),
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            FieldType::Checklist => row_builder.insert_checklist_cell(vec![
              ("Have breakfast".to_string(), true),
              ("Have lunch".to_string(), true),
              ("Take a nap".to_string(), false),
              ("Have dinner".to_string(), true),
              ("Shower and head to bed".to_string(), false),
            ]),
            _ => "".to_owned(),
          };
        }
      },
      2 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("C"),
            FieldType::Number => row_builder.insert_number_cell("3"),
            FieldType::DateTime => {
              row_builder.insert_date_cell(1647251762, None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::MultiSelect => row_builder.insert_multi_select_cell(|mut options| {
              vec![options.remove(1), options.remove(0), options.remove(0)]
            }),
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1668704685, None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(0))
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("false"),
            FieldType::Checklist => {
              row_builder.insert_checklist_cell(vec![("Task 1".to_string(), true)])
            },
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
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },
            FieldType::MultiSelect => row_builder
              .insert_multi_select_cell(|mut options| vec![options.remove(1), options.remove(1)]),
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
            FieldType::DateTime => {
              row_builder.insert_date_cell(1671938394, None, None, &field_type)
            },
            FieldType::SingleSelect => {
              row_builder.insert_single_select_cell(|mut options| options.remove(1))
            },
            FieldType::MultiSelect => {
              row_builder.insert_multi_select_cell(|mut options| vec![options.remove(1)])
            },
            FieldType::Checkbox => row_builder.insert_checkbox_cell("true"),
            FieldType::Checklist => row_builder.insert_checklist_cell(vec![
              ("Sprint".to_string(), true),
              ("Sprint some more".to_string(), false),
              ("Rest".to_string(), true),
            ]),
            _ => "".to_owned(),
          };
        }
      },
      6 => {
        row_builder.insert_text_cell("CB");
      },
      _ => {},
    }

    let row = row_builder.build();
    rows.push(row);
  }

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

pub fn make_no_date_test_grid() -> DatabaseData {
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
        let mut type_option = NumberTypeOption::default();
        type_option.set_format(NumberFormat::USD);

        let number_field = FieldBuilder::new(field_type, type_option)
          .name("Price")
          .build();
        fields.push(number_field);
      },
      _ => {},
    }
  }

  let field_settings = default_field_settings_for_fields(&fields, DatabaseLayout::Grid);

  for i in 0..3 {
    let mut row_builder = TestRowBuilder::new(&database_id, gen_row_id(), &fields);
    match i {
      0 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("A"),
            FieldType::Number => row_builder.insert_number_cell("1"),
            _ => "".to_owned(),
          };
        }
      },
      1 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell(""),
            FieldType::Number => row_builder.insert_number_cell("2"),
            _ => "".to_owned(),
          };
        }
      },
      2 => {
        for field_type in FieldType::iter() {
          match field_type {
            FieldType::RichText => row_builder.insert_text_cell("C"),
            FieldType::Number => row_builder.insert_number_cell("3"),
            _ => "".to_owned(),
          };
        }
      },
      _ => {},
    }

    let row = row_builder.build();
    rows.push(row);
  }

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
