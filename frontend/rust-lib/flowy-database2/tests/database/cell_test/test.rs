use crate::database::cell_test::script::CellScript::UpdateCell;
use crate::database::cell_test::script::DatabaseCellTest;
use collab_database::fields::date_type_option::DateCellData;
use collab_database::fields::media_type_option::{MediaFile, MediaFileType, MediaUploadType};
use collab_database::fields::select_type_option::{MultiSelectTypeOption, SingleSelectTypeOption};
use collab_database::fields::url_type_option::URLCellData;
use flowy_database2::entities::{FieldType, MediaCellChangeset};
use flowy_database2::services::field::{
  ChecklistCellChangeset, ChecklistCellInsertChangeset, DateCellChangeset, RelationCellChangeset,
  SelectOptionCellChangeset, StringCellData, TimeCellData,
};
use lib_infra::box_any::BoxAny;
use std::time::Duration;

#[tokio::test]
async fn grid_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let fields = test.get_fields().await;
  let rows = &test.rows;

  let mut scripts = vec![];
  for row in rows.iter() {
    for field in &fields {
      let field_type = FieldType::from(field.field_type);
      if field_type == FieldType::LastEditedTime || field_type == FieldType::CreatedTime {
        continue;
      }
      let cell_changeset = match field_type {
        FieldType::RichText => BoxAny::new("".to_string()),
        FieldType::Number => BoxAny::new("123".to_string()),
        FieldType::DateTime => BoxAny::new(DateCellChangeset {
          date: Some(123),
          ..Default::default()
        }),
        FieldType::SingleSelect => {
          let type_option = field
            .get_type_option::<SingleSelectTypeOption>(field.field_type)
            .unwrap();
          BoxAny::new(SelectOptionCellChangeset::from_insert_option_id(
            &type_option.options.first().unwrap().id,
          ))
        },
        FieldType::MultiSelect => {
          let type_option = field
            .get_type_option::<MultiSelectTypeOption>(field.field_type)
            .unwrap();
          BoxAny::new(SelectOptionCellChangeset::from_insert_option_id(
            &type_option.options.first().unwrap().id,
          ))
        },
        FieldType::Checklist => BoxAny::new(ChecklistCellChangeset {
          insert_tasks: vec![ChecklistCellInsertChangeset::new(
            "new option".to_string(),
            false,
          )],
          ..Default::default()
        }),
        FieldType::Checkbox => BoxAny::new("1".to_string()),
        FieldType::URL => BoxAny::new("1".to_string()),
        FieldType::Relation => BoxAny::new(RelationCellChangeset {
          inserted_row_ids: vec!["abcdefabcdef".to_string().into()],
          ..Default::default()
        }),
        FieldType::Media => BoxAny::new(MediaCellChangeset {
          inserted_files: vec![MediaFile {
            id: "abcdefghijk".to_string(),
            name: "link".to_string(),
            url: "https://www.appflowy.io".to_string(),
            file_type: MediaFileType::Link,
            upload_type: MediaUploadType::Network,
          }],
          removed_ids: vec![],
        }),
        _ => BoxAny::new("".to_string()),
      };

      scripts.push(UpdateCell {
        view_id: test.view_id.clone(),
        field_id: field.id.clone(),
        row_id: row.id.clone(),
        changeset: cell_changeset,
        is_err: false,
      });
    }
  }

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &text_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    let text = StringCellData::from(row_cell.cell.as_ref().unwrap());
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
  let url_field = test.get_first_field(FieldType::URL).await;
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &url_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    if let Some(cell) = row_cell.cell.as_ref() {
      let cell = URLCellData::from(cell);
      if i == 0 {
        assert_eq!(
          cell.data.as_str(),
          "AppFlowy website - https://www.appflowy.io"
        );
      }
    }
  }
}

#[tokio::test]
async fn update_updated_at_field_on_other_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let updated_at_field = test.get_first_field(FieldType::LastEditedTime).await;

  let text_field = test
    .fields
    .iter()
    .find(|&f| FieldType::from(f.field_type) == FieldType::RichText)
    .unwrap();

  let before_update_timestamp = chrono::offset::Utc::now().timestamp();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.rows[0].id.clone(),
      field_id: text_field.id.clone(),
      changeset: BoxAny::new("change".to_string()),
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

#[tokio::test]
async fn time_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time).await;
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &time_field.id)
    .await;

  if let Some(cell) = cells[0].cell.as_ref() {
    let cell = TimeCellData::from(cell);

    assert!(cell.0.is_some());
    assert_eq!(cell.0.unwrap_or_default(), 75);
  }
}
