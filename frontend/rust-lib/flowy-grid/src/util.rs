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

    // MultiSelect
    let apple_option = SelectOptionPB::new("Apple");
    let banana_option = SelectOptionPB::new("Banana");
    let pear_option = SelectOptionPB::new("Pear");
    let multi_select_type_option = MultiSelectTypeOptionBuilder::default()
        .add_option(banana_option.clone())
        .add_option(apple_option.clone())
        .add_option(pear_option.clone());
    let multi_select_field = FieldBuilder::new(multi_select_type_option)
        .name("Fruit")
        .visibility(true)
        .build();
    let multi_select_field_id = multi_select_field.id.clone();
    grid_builder.add_field(multi_select_field);

    // Number
    let number_type_option = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
    let number_field = FieldBuilder::new(number_type_option)
        .name("Price")
        .visibility(true)
        .build();
    let number_field_id = number_field.id.clone();
    grid_builder.add_field(number_field);

    // Checkbox
    let checkbox_type_option = CheckboxTypeOptionBuilder::default();
    let checkbox_field = FieldBuilder::new(checkbox_type_option).name("Reimbursement").build();
    let checkbox_field_id = checkbox_field.id.clone();
    grid_builder.add_field(checkbox_field);

    // Url
    let url_type_option = URLTypeOptionBuilder::default();
    let url_field = FieldBuilder::new(url_type_option).name("Shop Link").build();
    let url_field_id = url_field.id.clone();
    grid_builder.add_field(url_field);

    // Insert rows
    for i in 0..10 {
        // insert single select
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, not_started_option.id.clone());
        // insert multi select
        row_builder.insert_select_option_cell(&multi_select_field_id, apple_option.id.clone());
        row_builder.insert_select_option_cell(&multi_select_field_id, banana_option.id.clone());
        // insert text
        row_builder.insert_text_cell(&text_field_id, format!("Card {}", i));
        // insert date
        row_builder.insert_date_cell(&date_field_id, timestamp);
        // number
        row_builder.insert_number_cell(&number_field_id, i);
        // checkbox
        row_builder.insert_checkbox_cell(&checkbox_field_id, i % 2 == 0);
        // url
        row_builder.insert_url_cell(&url_field_id, "https://appflowy.io".to_string());

        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    grid_builder.build()
}
