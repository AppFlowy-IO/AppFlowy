use crate::services::field::*;
use flowy_grid_data_model::entities::{BuildGridContext, FieldType};
use flowy_sync::client_grid::GridBuilder;

pub fn make_default_grid() -> BuildGridContext {
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .build();

    let single_select = SingleSelectTypeOptionBuilder::default()
        .option(SelectOption::new("Done"))
        .option(SelectOption::new("Unknown"))
        .option(SelectOption::new("Progress"));

    let single_select_field = FieldBuilder::new(single_select).name("Status").visibility(true).build();

    GridBuilder::default()
        .add_field(text_field)
        .add_field(single_select_field)
        .add_empty_row()
        .add_empty_row()
        .add_empty_row()
        .build()
}
