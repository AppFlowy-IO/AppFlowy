use flowy_database2::entities::{CellChangesetPB, FieldType};
use flowy_database2::services::cell::ToCellChangeset;
use flowy_database2::services::field::{
  ChecklistTypeOption, MultiSelectTypeOption, SelectOptionCellChangeset, SingleSelectTypeOption,
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
        FieldType::DateTime => make_date_cell_string("123"),
        FieldType::SingleSelect => {
          let type_option = field
            .get_type_option::<SingleSelectTypeOption>(&field.field_type)
            .unwrap();
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::MultiSelect => {
          let type_option = field
            .get_type_option::<MultiSelectTypeOption>(&field.field_type)
            .unwrap();
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::Checklist => {
          let type_option = field
            .get_type_option::<ChecklistTypeOption>(&field.field_type)
            .unwrap();
          SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
            .to_cell_changeset_str()
        },
        FieldType::Checkbox => "1".to_string(),
        FieldType::URL => "1".to_string(),
      };

      scripts.push(UpdateCell {
        changeset: CellChangesetPB {
          view_id: test.view_id.clone(),
          row_id: row.id.into(),
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
async fn text_cell_date_test() {
  let test = DatabaseCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText);

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &text_field.id)
    .await;

  for (i, cell) in cells.into_iter().enumerate() {
    let text = StrCellData::from(cell.as_ref());
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
async fn url_cell_date_test() {
  let test = DatabaseCellTest::new().await;
  let url_field = test.get_first_field(FieldType::URL);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &url_field.id)
    .await;

  for (i, cell) in cells.into_iter().enumerate() {
    let cell = URLCellData::from(cell.as_ref());
    if i == 0 {
      assert_eq!(cell.url.as_str(), "https://www.appflowy.io/");
    }
  }
}
