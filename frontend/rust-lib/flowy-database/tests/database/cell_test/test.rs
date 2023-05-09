use crate::database::cell_test::script::CellScript::*;
use crate::database::cell_test::script::DatabaseCellTest;
use crate::database::field_test::util::make_date_cell_string;
use flowy_database::entities::{CellChangesetPB, FieldType};
use flowy_database::services::cell::ToCellChangesetString;
use flowy_database::services::field::selection_type_option::SelectOptionCellChangeset;
use flowy_database::services::field::{
  ChecklistTypeOptionPB, MultiSelectTypeOptionPB, SingleSelectTypeOptionPB,
};

#[tokio::test]
async fn grid_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let field_revs = &test.field_revs;
  let row_revs = &test.row_revs;
  let grid_blocks = &test.block_meta_revs;

  // For the moment, We only have one block to store rows
  let block_id = &grid_blocks.first().unwrap().block_id;

  let mut scripts = vec![];
  for (_, row_rev) in row_revs.iter().enumerate() {
    for field_rev in field_revs {
      let field_type: FieldType = field_rev.ty.into();
      let data = match field_type {
        FieldType::RichText => "".to_string(),
        FieldType::Number => "123".to_string(),
        FieldType::DateTime | FieldType::UpdatedAt | FieldType::CreatedAt => {
          make_date_cell_string("123")
        },
        FieldType::SingleSelect => {
          let type_option = SingleSelectTypeOptionPB::from(field_rev);
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::MultiSelect => {
          let type_option = MultiSelectTypeOptionPB::from(field_rev);
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::Checklist => {
          let type_option = ChecklistTypeOptionPB::from(field_rev);
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::Checkbox => "1".to_string(),
        FieldType::URL => "1".to_string(),
      };

      scripts.push(UpdateCell {
        changeset: CellChangesetPB {
          view_id: block_id.to_string(),
          row_id: row_rev.id.clone(),
          field_id: field_rev.id.clone(),
          type_cell_data: data,
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
  let text_field = test.get_first_field_rev(FieldType::RichText);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &text_field.id)
    .await
    .unwrap();

  for (i, cell) in cells.into_iter().enumerate() {
    let text = cell.into_text_field_cell_data().unwrap();
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
  let url_field = test.get_first_field_rev(FieldType::URL);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &url_field.id)
    .await
    .unwrap();

  for (i, cell) in cells.into_iter().enumerate() {
    let url_cell_data = cell.into_url_field_cell_data().unwrap();
    if i == 0 {
      assert_eq!(url_cell_data.url.as_str(), "https://www.appflowy.io/");
    }
  }
}

#[tokio::test]
async fn update_updated_at_field_on_other_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let updated_at_field = test.get_first_field_rev(FieldType::UpdatedAt).clone();

  let field_revs = test.field_revs.clone();
  let row_revs = &test.row_revs;
  let grid_blocks = &test.block_meta_revs;
  let block_id = &grid_blocks.first().unwrap().block_id;
  let text_field = field_revs
    .iter()
    .find(|&f| <u8 as Into<FieldType>>::into(f.ty) == FieldType::RichText)
    .unwrap();

  let before_update_timestamp = chrono::offset::Utc::now().timestamp();
  test
    .run_script(UpdateCell {
      changeset: CellChangesetPB {
        view_id: block_id.to_string(),
        row_id: row_revs[0].id.clone(),
        field_id: text_field.id.clone(),
        type_cell_data: "change".to_string(),
      },
      is_err: false,
    })
    .await;
  let after_update_timestamp = chrono::offset::Utc::now().timestamp();

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &updated_at_field.id)
    .await
    .unwrap();
  for (i, cell) in cells.into_iter().enumerate() {
    let timestamp = cell.into_date_field_cell_data().unwrap().timestamp.unwrap();
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
