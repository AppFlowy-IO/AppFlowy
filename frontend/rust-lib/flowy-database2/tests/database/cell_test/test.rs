use std::time::Duration;

use flowy_database2::entities::{CellChangesetPB, FieldType};
use flowy_database2::services::cell::ToCellChangeset;
use flowy_database2::services::field::checklist_type_option::ChecklistCellChangeset;
use flowy_database2::services::field::{
  DateCellData, MultiSelectTypeOption, SelectOptionCellChangeset, SingleSelectTypeOption,
  StrCellData, URLCellData,
};

use crate::database::cell_test::script::CellScript::UpdateCell;
use crate::database::cell_test::script::DatabaseCellTest;
use crate::database::field_test::util::make_date_cell_string;

#[tokio::test]
async fn grid_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let fields = test.get_fields();
  let rows = &test.rows;

  let mut scripts = vec![];
  for (_, row) in rows.iter().enumerate() {
    for field in &fields {
      let field_type = FieldType::from(field.field_type);
      let cell_changeset = match field_type {
        FieldType::RichText => "".to_string(),
        FieldType::Number => "123".to_string(),
        FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
          make_date_cell_string("123")
        },
        FieldType::SingleSelect => {
          let type_option = field
            .get_type_option::<SingleSelectTypeOption>(field.field_type)
            .unwrap();
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::MultiSelect => {
          let type_option = field
            .get_type_option::<MultiSelectTypeOption>(field.field_type)
            .unwrap();
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::Checklist => ChecklistCellChangeset {
          insert_options: vec!["new option".to_string()],
          ..Default::default()
        }
        .to_cell_changeset_str(),
        FieldType::Checkbox => "1".to_string(),
        FieldType::URL => "1".to_string(),
      };

      scripts.push(UpdateCell {
        changeset: CellChangesetPB {
          view_id: test.view_id.clone(),
          row_id: row.id.clone().into(),
          field_id: field.id.clone(),
          cell_changeset,
        },
        is_err: false,
      });
    }
  }

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText);

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &text_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    let text = StrCellData::from(row_cell.cell.as_ref().unwrap());
    match i {
      0 => assert_eq!(text.as_str(), "A"),
      1 => assert_eq!(text.as_str(), ""),
      2 => assert_eq!(text.as_str(), "C"),
      3 => assert_eq!(text.as_str(), "DA"),
      4 => assert_eq!(text.as_str(), "AE"),
      5 => assert_eq!(text.as_str(), "AE"),
      _ => {},
    }
  }
}

#[tokio::test]
async fn url_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let url_field = test.get_first_field(FieldType::URL);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &url_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    if let Some(cell) = row_cell.cell.as_ref() {
      let cell = URLCellData::from(cell);
      if i == 0 {
        assert_eq!(cell.url.as_str(), "https://www.appflowy.io/");
      }
    }
  }
}

#[tokio::test]
async fn update_updated_at_field_on_other_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let updated_at_field = test.get_first_field(FieldType::LastEditedTime);

  let text_field = test
    .fields
    .iter()
    .find(|&f| FieldType::from(f.field_type) == FieldType::RichText)
    .unwrap();

  let before_update_timestamp = chrono::offset::Utc::now().timestamp();
  test
    .run_script(UpdateCell {
      changeset: CellChangesetPB {
        view_id: test.view_id.clone(),
        row_id: test.rows[0].id.to_string(),
        field_id: text_field.id.clone(),
        cell_changeset: "change".to_string(),
      },
      is_err: false,
    })
    .await;

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &updated_at_field.id)
    .await;

  tokio::time::sleep(Duration::from_millis(500)).await;
  let after_update_timestamp = chrono::offset::Utc::now().timestamp();
  assert!(!cells.is_empty());
  for (i, row_cell) in cells.into_iter().enumerate() {
    let timestamp = DateCellData::from(row_cell.cell.as_ref().unwrap())
      .timestamp
      .unwrap();
    println!(
      "{}, bf: {}, af: {}",
      timestamp, before_update_timestamp, after_update_timestamp
    );
    match i {
      0 => assert!(
        timestamp >= before_update_timestamp && timestamp <= after_update_timestamp,
        "{} >= {} && {} <= {}",
        timestamp,
        before_update_timestamp,
        timestamp,
        after_update_timestamp
      ),
      1 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      2 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      3 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      4 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      5 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      _ => {},
    }
  }
}
