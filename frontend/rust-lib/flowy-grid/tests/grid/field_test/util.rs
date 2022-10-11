use flowy_grid::entities::*;
use flowy_grid::services::field::selection_type_option::SelectOptionPB;
use flowy_grid::services::field::*;
use flowy_grid_data_model::revision::*;

pub fn create_text_field(grid_id: &str) -> (CreateFieldParams, FieldRevision) {
    let mut field_rev = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .build();

    let cloned_field_rev = field_rev.clone();

    let type_option_data = field_rev
        .get_type_option::<RichTextTypeOptionPB>(field_rev.ty)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let type_option_builder = type_option_builder_from_bytes(type_option_data.clone(), &field_rev.ty.into());
    field_rev.insert_type_option(type_option_builder.data_format());

    let params = CreateFieldParams {
        grid_id: grid_id.to_owned(),
        field_type: field_rev.ty.into(),
        type_option_data: Some(type_option_data),
    };
    (params, cloned_field_rev)
}

pub fn create_single_select_field(grid_id: &str) -> (CreateFieldParams, FieldRevision) {
    let single_select = SingleSelectTypeOptionBuilder::default()
        .add_option(SelectOptionPB::new("Done"))
        .add_option(SelectOptionPB::new("Progress"));

    let mut field_rev = FieldBuilder::new(single_select).name("Name").visibility(true).build();
    let cloned_field_rev = field_rev.clone();
    let type_option_data = field_rev
        .get_type_option::<SingleSelectTypeOptionPB>(field_rev.ty)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let type_option_builder = type_option_builder_from_bytes(type_option_data.clone(), &field_rev.ty.into());
    field_rev.insert_type_option(type_option_builder.data_format());

    let params = CreateFieldParams {
        grid_id: grid_id.to_owned(),
        field_type: field_rev.ty.into(),
        type_option_data: Some(type_option_data),
    };
    (params, cloned_field_rev)
}

//  The grid will contains all existing field types and there are three empty rows in this grid.

pub fn make_date_cell_string(s: &str) -> String {
    serde_json::to_string(&DateCellChangesetPB {
        date: Some(s.to_string()),
        time: None,
    })
    .unwrap()
}
