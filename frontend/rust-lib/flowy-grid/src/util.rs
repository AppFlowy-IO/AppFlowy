use crate::services::field::*;
use flowy_grid_data_model::entities::{BuildGridContext, FieldType};
use flowy_sync::client_grid::GridBuilder;

pub fn make_default_grid() -> BuildGridContext {
    // text
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .primary(true)
        .build();

    // single select
    let single_select = SingleSelectTypeOptionBuilder::default();
    let single_select_field = FieldBuilder::new(single_select).name("Type").visibility(true).build();

    // checkbox
    let checkbox_field = FieldBuilder::from_field_type(&FieldType::Checkbox)
        .name("Done")
        .visibility(true)
        .build();

    GridBuilder::default()
        .add_field(text_field)
        .add_field(single_select_field)
        .add_field(checkbox_field)
        .add_empty_row()
        .add_empty_row()
        .add_empty_row()
        .build()
}
