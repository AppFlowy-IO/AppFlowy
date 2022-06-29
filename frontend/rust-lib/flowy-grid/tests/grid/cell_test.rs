use crate::grid::field_util::make_date_cell_string;
use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid::services::field::{MultiSelectTypeOption, SelectOptionCellContentChangeset, SingleSelectTypeOption};
use flowy_grid_data_model::entities::{CellChangeset, FieldType};

#[tokio::test]
async fn grid_cell_update() {
    let mut test = GridEditorTest::new().await;
    let field_revs = &test.field_revs;
    let row_revs = &test.row_revs;
    let grid_blocks = &test.block_meta_revs;

    // For the moment, We only have one block to store rows
    let block_id = &grid_blocks.first().unwrap().block_id;

    let mut scripts = vec![];
    for (_, row_rev) in row_revs.iter().enumerate() {
        for field_rev in field_revs {
            let data = match field_rev.field_type {
                FieldType::RichText => "".to_string(),
                FieldType::Number => "123".to_string(),
                FieldType::DateTime => make_date_cell_string("123"),
                FieldType::SingleSelect => {
                    let type_option = SingleSelectTypeOption::from(field_rev);
                    SelectOptionCellContentChangeset::from_insert(&type_option.options.first().unwrap().id).to_str()
                }
                FieldType::MultiSelect => {
                    let type_option = MultiSelectTypeOption::from(field_rev);
                    SelectOptionCellContentChangeset::from_insert(&type_option.options.first().unwrap().id).to_str()
                }
                FieldType::Checkbox => "1".to_string(),
                FieldType::URL => "1".to_string(),
            };

            scripts.push(UpdateCell {
                changeset: CellChangeset {
                    grid_id: block_id.to_string(),
                    row_id: row_rev.id.clone(),
                    field_id: field_rev.id.clone(),
                    cell_content_changeset: Some(data),
                },
                is_err: false,
            });
        }
    }

    test.run_scripts(scripts).await;
}
