use crate::services::field::*;
use flowy_collaboration::client_grid::{BuildGridInfo, GridBuilder};
use flowy_grid_data_model::entities::FieldType;

pub fn make_default_grid(grid_id: &str) -> BuildGridInfo {
    let text_field = FieldBuilder::new(RichTextTypeOptionsBuilder::new())
        .name("Name")
        .visibility(true)
        .field_type(FieldType::RichText)
        .build();

    let single_select = SingleSelectTypeOptionsBuilder::new()
        .option(SelectOption::new("Done"))
        .option(SelectOption::new("Progress"));

    let single_select_field = FieldBuilder::new(single_select)
        .name("Name")
        .visibility(true)
        .field_type(FieldType::SingleSelect)
        .build();

    GridBuilder::new(grid_id)
        .add_field(text_field)
        .add_field(single_select_field)
        .add_empty_row()
        .add_empty_row()
        .add_empty_row()
        .build()
        .unwrap()
}
