use flowy_grid::entities::*;
use flowy_grid::services::field::selection_type_option::SelectOptionPB;
use flowy_grid::services::field::*;
use flowy_grid_data_model::revision::*;

pub fn create_text_field(grid_id: &str) -> (InsertFieldParams, FieldRevision) {
    let field_rev = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .build();

    let cloned_field_rev = field_rev.clone();

    let type_option_data = field_rev
        .get_type_option_entry::<RichTextTypeOptionPB>(field_rev.ty)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let field = FieldPB {
        id: field_rev.id,
        name: field_rev.name,
        desc: field_rev.desc,
        field_type: field_rev.ty.into(),
        frozen: field_rev.frozen,
        visibility: field_rev.visibility,
        width: field_rev.width,
        is_primary: false,
    };

    let params = InsertFieldParams {
        grid_id: grid_id.to_owned(),
        field,
        type_option_data,
        start_field_id: None,
    };
    (params, cloned_field_rev)
}

pub fn create_single_select_field(grid_id: &str) -> (InsertFieldParams, FieldRevision) {
    let single_select = SingleSelectTypeOptionBuilder::default()
        .add_option(SelectOptionPB::new("Done"))
        .add_option(SelectOptionPB::new("Progress"));

    let field_rev = FieldBuilder::new(single_select).name("Name").visibility(true).build();
    let cloned_field_rev = field_rev.clone();
    let type_option_data = field_rev
        .get_type_option_entry::<SingleSelectTypeOptionPB>(field_rev.ty)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let field = FieldPB {
        id: field_rev.id,
        name: field_rev.name,
        desc: field_rev.desc,
        field_type: field_rev.ty.into(),
        frozen: field_rev.frozen,
        visibility: field_rev.visibility,
        width: field_rev.width,
        is_primary: false,
    };

    let params = InsertFieldParams {
        grid_id: grid_id.to_owned(),
        field,
        type_option_data,
        start_field_id: None,
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
