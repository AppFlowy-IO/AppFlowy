use crate::grid::cell_test::script::CellScript::*;
use crate::grid::cell_test::script::GridCellTest;
use crate::grid::field_test::util::make_date_cell_string;
use flowy_grid::entities::{CellChangesetPB, FieldType};
use flowy_grid::services::cell::ToCellChangesetString;
use flowy_grid::services::field::selection_type_option::SelectOptionCellChangeset;
use flowy_grid::services::field::{ChecklistTypeOptionPB, MultiSelectTypeOptionPB, SingleSelectTypeOptionPB};

#[tokio::test]
async fn grid_cell_update() {
    let mut test = GridCellTest::new().await;
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
                FieldType::DateTime => make_date_cell_string("123"),
                FieldType::SingleSelect => {
                    let type_option = SingleSelectTypeOptionPB::from(field_rev);
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
                        .to_cell_changeset_str()
                }
                FieldType::MultiSelect => {
                    let type_option = MultiSelectTypeOptionPB::from(field_rev);
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
                        .to_cell_changeset_str()
                }
                FieldType::Checklist => {
                    let type_option = ChecklistTypeOptionPB::from(field_rev);
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id)
                        .to_cell_changeset_str()
                }
                FieldType::Checkbox => "1".to_string(),
                FieldType::URL => "1".to_string(),
            };

            scripts.push(UpdateCell {
                changeset: CellChangesetPB {
                    grid_id: block_id.to_string(),
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
async fn text_cell_date_test() {
    let test = GridCellTest::new().await;
    let text_field = test.get_first_field_rev(FieldType::RichText);
    let cells = test
        .editor
        .get_cells_for_field(&test.view_id, &text_field.id)
        .await
        .unwrap();

    for (i, cell) in cells.iter().enumerate() {
        let text = cell.get_text_field_cell_data().unwrap();
        match i {
            0 => assert_eq!(text.as_str(), "A"),
            1 => assert_eq!(text.as_str(), ""),
            2 => assert_eq!(text.as_str(), "C"),
            3 => assert_eq!(text.as_str(), "DA"),
            4 => assert_eq!(text.as_str(), "AE"),
            5 => assert_eq!(text.as_str(), "AE"),
            _ => {}
        }
    }
}

#[tokio::test]
async fn url_cell_date_test() {
    let test = GridCellTest::new().await;
    let url_field = test.get_first_field_rev(FieldType::URL);
    let cells = test
        .editor
        .get_cells_for_field(&test.view_id, &url_field.id)
        .await
        .unwrap();

    for (i, cell) in cells.iter().enumerate() {
        let url_cell_data = cell.get_url_field_cell_data().unwrap();
        match i {
            0 => assert_eq!(url_cell_data.url.as_str(), "https://www.appflowy.io/"),
            _ => {}
        }
    }
}
