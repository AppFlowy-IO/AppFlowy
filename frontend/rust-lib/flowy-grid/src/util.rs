use crate::entities::FieldType;
use crate::services::field::*;
use crate::services::row::RowRevisionBuilder;
use flowy_sync::client_grid::GridBuilder;
use grid_rev_model::BuildGridContext;

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
        .name("Description")
        .visibility(true)
        .primary(true)
        .build();
    let text_field_id = text_field.id.clone();
    grid_builder.add_field(text_field);

    // single select
    let to_do_option = SelectOptionPB::with_color("To Do", SelectOptionColorPB::Purple);
    let doing_option = SelectOptionPB::with_color("Doing", SelectOptionColorPB::Orange);
    let done_option = SelectOptionPB::with_color("Done", SelectOptionColorPB::Yellow);
    let single_select_type_option = SingleSelectTypeOptionBuilder::default()
        .add_option(to_do_option.clone())
        .add_option(doing_option)
        .add_option(done_option);
    let single_select_field = FieldBuilder::new(single_select_type_option)
        .name("Status")
        .visibility(true)
        .build();
    let single_select_field_id = single_select_field.id.clone();
    grid_builder.add_field(single_select_field);

    for i in 0..3 {
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, vec![to_do_option.id.clone()]);
        let data = format!("Card {}", i + 1);
        row_builder.insert_text_cell(&text_field_id, data);
        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    grid_builder.build()
}

pub fn make_default_calendar() -> BuildGridContext {
    let mut grid_builder = GridBuilder::new();
    // text
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Description")
        .visibility(true)
        .primary(true)
        .build();
    grid_builder.add_field(text_field);

    // date
    let date_type_option = DateTypeOptionBuilder::default();
    let date_field = FieldBuilder::new(date_type_option)
        .name("Date")
        .visibility(true)
        .build();
    grid_builder.add_field(date_field);

    // single select
    let multi_select_type_option = MultiSelectTypeOptionBuilder::default();
    let multi_select_field = FieldBuilder::new(multi_select_type_option)
        .name("Tags")
        .visibility(true)
        .build();
    grid_builder.add_field(multi_select_field);
    grid_builder.build()
}

#[allow(dead_code)]
pub fn make_default_board_2() -> BuildGridContext {
    let mut grid_builder = GridBuilder::new();
    // text
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Description")
        .visibility(true)
        .primary(true)
        .build();
    let text_field_id = text_field.id.clone();
    grid_builder.add_field(text_field);

    // single select
    let to_do_option = SelectOptionPB::with_color("To Do", SelectOptionColorPB::Purple);
    let doing_option = SelectOptionPB::with_color("Doing", SelectOptionColorPB::Orange);
    let done_option = SelectOptionPB::with_color("Done", SelectOptionColorPB::Yellow);
    let single_select_type_option = SingleSelectTypeOptionBuilder::default()
        .add_option(to_do_option.clone())
        .add_option(doing_option.clone())
        .add_option(done_option.clone());
    let single_select_field = FieldBuilder::new(single_select_type_option)
        .name("Status")
        .visibility(true)
        .build();
    let single_select_field_id = single_select_field.id.clone();
    grid_builder.add_field(single_select_field);

    // MultiSelect
    let work_option = SelectOptionPB::with_color("Work", SelectOptionColorPB::Aqua);
    let travel_option = SelectOptionPB::with_color("Travel", SelectOptionColorPB::Green);
    let fun_option = SelectOptionPB::with_color("Fun", SelectOptionColorPB::Lime);
    let health_option = SelectOptionPB::with_color("Health", SelectOptionColorPB::Pink);
    let multi_select_type_option = MultiSelectTypeOptionBuilder::default()
        .add_option(travel_option.clone())
        .add_option(work_option.clone())
        .add_option(fun_option.clone())
        .add_option(health_option.clone());
    let multi_select_field = FieldBuilder::new(multi_select_type_option)
        .name("Tags")
        .visibility(true)
        .build();
    let multi_select_field_id = multi_select_field.id.clone();
    grid_builder.add_field(multi_select_field);

    for i in 0..3 {
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, vec![to_do_option.id.clone()]);
        match i {
            0 => {
                row_builder.insert_text_cell(&text_field_id, "Update AppFlowy Website".to_string());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![work_option.id.clone()]);
            }
            1 => {
                row_builder.insert_text_cell(&text_field_id, "Learn French".to_string());
                let mut options = SelectOptionIds::new();
                options.push(fun_option.id.clone());
                options.push(travel_option.id.clone());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![options.to_string()]);
            }

            2 => {
                row_builder.insert_text_cell(&text_field_id, "Exercise 4x/week".to_string());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![fun_option.id.clone()]);
            }
            _ => {}
        }
        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    for i in 0..3 {
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, vec![doing_option.id.clone()]);
        match i {
            0 => {
                row_builder.insert_text_cell(&text_field_id, "Learn how to swim".to_string());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![fun_option.id.clone()]);
            }
            1 => {
                row_builder.insert_text_cell(&text_field_id, "Meditate 10 mins each day".to_string());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![health_option.id.clone()]);
            }

            2 => {
                row_builder.insert_text_cell(&text_field_id, "Write atomic essays ".to_string());
                let mut options = SelectOptionIds::new();
                options.push(fun_option.id.clone());
                options.push(work_option.id.clone());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![options.to_string()]);
            }
            _ => {}
        }
        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    for i in 0..2 {
        let mut row_builder = RowRevisionBuilder::new(grid_builder.block_id(), grid_builder.field_revs());
        row_builder.insert_select_option_cell(&single_select_field_id, vec![done_option.id.clone()]);
        match i {
            0 => {
                row_builder.insert_text_cell(&text_field_id, "Publish an article".to_string());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![work_option.id.clone()]);
            }
            1 => {
                row_builder.insert_text_cell(&text_field_id, "Visit Chicago".to_string());
                let mut options = SelectOptionIds::new();
                options.push(travel_option.id.clone());
                options.push(fun_option.id.clone());
                row_builder.insert_select_option_cell(&multi_select_field_id, vec![options.to_string()]);
            }

            _ => {}
        }
        let row = row_builder.build();
        grid_builder.add_row(row);
    }

    grid_builder.build()
}
