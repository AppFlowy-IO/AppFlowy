use crate::grid::cell_test::script::CellScript::*;
use crate::grid::cell_test::script::GridCellTest;
use crate::grid::field_test::util::make_date_cell_string;
use flowy_grid::entities::{CellChangesetPB, FieldType};
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
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id).to_str()
                }
                FieldType::MultiSelect => {
                    let type_option = MultiSelectTypeOptionPB::from(field_rev);
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id).to_str()
                }
                FieldType::Checklist => {
                    let type_option = ChecklistTypeOptionPB::from(field_rev);
                    SelectOptionCellChangeset::from_insert_option_id(&type_option.options.first().unwrap().id).to_str()
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
