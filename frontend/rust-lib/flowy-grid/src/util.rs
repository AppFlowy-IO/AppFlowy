use crate::entities::FieldType;
use crate::services::field::*;
use crate::services::row::RowRevisionBuilder;
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

pub fn make_default_board() -> BuildGridContext {
    let mut grid_builder = GridBuilder::new();
    // text
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .primary(true)
        .build();
    grid_builder.add_field(text_field);

    // single select
    let in_progress_option = SelectOptionPB::new("In progress");
    let not_started_option = SelectOptionPB::new("Not started");
    let done_option = SelectOptionPB::new("Done");
    let single_select = SingleSelectTypeOptionBuilder::default()
        .add_option(not_started_option.clone())
        .add_option(in_progress_option.clone())
        .add_option(done_option.clone());
    let single_select_field = FieldBuilder::new(single_select).name("Status").visibility(true).build();
    let single_select_field_id = single_select_field.id.clone();
    grid_builder.add_field(single_select_field);

    // rows
    for _ in 0..3 {
        grid_builder.add_row(
            RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs())
                .insert_select_option_cell(&single_select_field_id, not_started_option.id.clone())
                .build(),
        );
    }

    grid_builder.build()
}
