use crate::grid::field_test::script::FieldScript::*;
use crate::grid::field_test::script::GridFieldTest;
use crate::grid::field_test::util::*;
use flowy_grid::entities::FieldChangesetParams;
use flowy_grid::services::field::selection_type_option::SelectOptionPB;
use flowy_grid::services::field::SingleSelectTypeOptionPB;
use grid_rev_model::TypeOptionDataSerializer;

#[tokio::test]
async fn grid_create_field() {
    let mut test = GridFieldTest::new().await;
    let (params, field_rev) = create_text_field(&test.grid_id());

    let scripts = vec![
        CreateField { params },
        AssertFieldTypeOptionEqual {
            field_index: test.field_count(),
            expected_type_option_data: field_rev.get_type_option_str(field_rev.ty).unwrap(),
        },
    ];
    test.run_scripts(scripts).await;

    let (params, field_rev) = create_single_select_field(&test.grid_id());
    let scripts = vec![
        CreateField { params },
        AssertFieldTypeOptionEqual {
            field_index: test.field_count(),
            expected_type_option_data: field_rev.get_type_option_str(field_rev.ty).unwrap(),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_duplicate_field() {
    let mut test = GridFieldTest::new().await;
    let (params, _) = create_text_field(&test.grid_id());
    let field_count = test.field_count();
    let expected_field_count = field_count + 1;
    let scripts = vec![
        CreateField { params: params.clone() },
        AssertFieldCount(expected_field_count),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
    let mut test = GridFieldTest::new().await;
    let (params, _) = create_single_select_field(&test.grid_id());
    let create_field_index = test.field_count();
    let scripts = vec![CreateField { params }];
    test.run_scripts(scripts).await;

    let field_rev = (&*test.field_revs.clone().pop().unwrap()).clone();
    let changeset = FieldChangesetParams {
        field_id: field_rev.id.clone(),
        grid_id: test.grid_id(),
        ..Default::default()
    };

    let scripts = vec![
        UpdateField { changeset },
        AssertFieldTypeOptionEqual {
            field_index: create_field_index,
            expected_type_option_data: field_rev.get_type_option_str(field_rev.ty).unwrap(),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field() {
    let mut test = GridFieldTest::new().await;
    let (params, _) = create_single_select_field(&test.grid_id());
    let scripts = vec![CreateField { params }];
    let create_field_index = test.field_count();
    test.run_scripts(scripts).await;
    //
    let single_select_field = (&*test.field_revs.clone().pop().unwrap()).clone();
    let mut single_select_type_option = SingleSelectTypeOptionPB::from(&single_select_field);
    single_select_type_option.options.push(SelectOptionPB::new("Unknown"));

    let changeset = FieldChangesetParams {
        field_id: single_select_field.id.clone(),
        grid_id: test.grid_id(),
        frozen: Some(true),
        width: Some(1000),
        type_option_data: Some(single_select_type_option.protobuf_bytes().to_vec()),
        ..Default::default()
    };

    // The expected_field must be equal to the field that applied the changeset
    let mut expected_field_rev = single_select_field.clone();
    expected_field_rev.frozen = true;
    expected_field_rev.width = 1000;
    expected_field_rev.insert_type_option(&single_select_type_option);

    let scripts = vec![
        UpdateField { changeset },
        AssertFieldTypeOptionEqual {
            field_index: create_field_index,
            expected_type_option_data: expected_field_rev.get_type_option_str(expected_field_rev.ty).unwrap(),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_field() {
    let mut test = GridFieldTest::new().await;
    let original_field_count = test.field_count();
    let (params, _) = create_text_field(&test.grid_id());
    let scripts = vec![CreateField { params }];
    test.run_scripts(scripts).await;

    let text_field_rev = (&*test.field_revs.clone().pop().unwrap()).clone();
    let scripts = vec![
        DeleteField {
            field_rev: text_field_rev,
        },
        AssertFieldCount(original_field_count),
    ];
    test.run_scripts(scripts).await;
}
