use crate::entities::FieldType;
use crate::services::field::*;
use crate::services::row::RowRevisionBuilder;
use flowy_grid_data_model::revision::BuildGridContext;
use flowy_sync::client_grid::GridBuilder;
use lib_infra::util::timestamp;

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
    let text_field_id = text_field.id.clone();
    grid_builder.add_field(text_field);

    // date
    let date_type_option = DateTypeOptionBuilder::default();
    let date_field = FieldBuilder::new(date_type_option)
        .name("Date")
        .visibility(true)
        .build();
    let date_field_id = date_field.id.clone();
    let timestamp = timestamp();
    grid_builder.add_field(date_field);

    // single select
    let in_progress_option = SelectOptionPB::new("In progress");
    let not_started_option = SelectOptionPB::new("Not started");
    let done_option = SelectOptionPB::new("Done");
    let single_select_type_option = SingleSelectTypeOptionBuilder::default()
        .add_option(not_started_option.clone())
        .add_option(in_progress_option)
        .add_option(done_option);
    let single_select_field = FieldBuilder::new(single_select_type_option)
        .name("Status")
        .visibility(true)
        .build();
    let single_select_field_id = single_select_field.id.clone();
    grid_builder.add_field(single_select_field);

    // Insert rows
    for i in 0..10 {
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, not_started_option.id.clone());
        row_builder.insert_cell(&text_field_id, format!("Card {}", i));
        row_builder.insert_date_cell(&date_field_id, timestamp);
        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    grid_builder.build()
}
