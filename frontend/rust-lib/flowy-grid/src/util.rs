use crate::entities::FieldType;
use crate::services::field::*;
use flowy_grid_data_model::revision::BuildGridContext;
use flowy_sync::client_grid::GridBuilder;

pub fn make_default_grid() -> BuildGridContext {
    let mut grid_builder = GridBuilder::new();
    // text
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .primary(true)
        .build();
    grid_builder.add_field(text_field);

    // single select
    let single_select = SingleSelectTypeOptionBuilder::default();
    let single_select_field = FieldBuilder::new(single_select).name("Type").visibility(true).build();
    grid_builder.add_field(single_select_field);

    // checkbox
    let checkbox_field = FieldBuilder::from_field_type(&FieldType::Checkbox)
        .name("Done")
        .visibility(true)
        .build();
    grid_builder.add_field(checkbox_field);

    grid_builder.add_empty_row();
    grid_builder.add_empty_row();
    grid_builder.add_empty_row();
    grid_builder.build()
}
