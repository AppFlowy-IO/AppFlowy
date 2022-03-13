use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid::services::field::{SelectOption, SingleSelectDescription};
use flowy_grid_data_model::entities::{FieldChangeset, GridBlock, GridBlockChangeset};

#[tokio::test]
async fn default_grid_test() {
    let scripts = vec![AssertFieldCount(2), AssertGridMetaPad];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_field() {
    let text_field = create_text_field();
    let single_select_field = create_single_select_field();
    let scripts = vec![
        AssertFieldCount(2),
        CreateField {
            field: text_field.clone(),
        },
        AssertFieldEqual {
            field_index: 2,
            field: text_field,
        },
        AssertFieldCount(3),
        CreateField {
            field: single_select_field.clone(),
        },
        AssertFieldEqual {
            field_index: 3,
            field: single_select_field,
        },
        AssertFieldCount(4),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_duplicate_field() {
    let text_field = create_text_field();
    let scripts = vec![
        AssertFieldCount(2),
        CreateField {
            field: text_field.clone(),
        },
        AssertFieldCount(3),
        CreateField {
            field: text_field.clone(),
        },
        AssertFieldCount(3),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
    let single_select_field = create_single_select_field();
    let change = FieldChangeset {
        field_id: single_select_field.id.clone(),
        name: None,
        desc: None,
        field_type: None,
        frozen: None,
        visibility: None,
        width: None,
        type_options: None,
    };

    let scripts = vec![
        CreateField {
            field: single_select_field.clone(),
        },
        UpdateField { change },
        AssertFieldEqual {
            field_index: 2,
            field: single_select_field,
        },
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field() {
    let single_select_field = create_single_select_field();
    let mut cloned_field = single_select_field.clone();

    let mut single_select_type_options = SingleSelectDescription::from(&single_select_field);
    single_select_type_options.options.push(SelectOption::new("Unknown"));

    let change = FieldChangeset {
        field_id: single_select_field.id.clone(),
        name: None,
        desc: None,
        field_type: None,
        frozen: Some(true),
        visibility: None,
        width: Some(1000),
        type_options: Some(single_select_type_options.clone().into()),
    };

    cloned_field.frozen = true;
    cloned_field.width = 1000;
    cloned_field.type_options = single_select_type_options.into();

    let scripts = vec![
        CreateField {
            field: single_select_field.clone(),
        },
        UpdateField { change },
        AssertFieldEqual {
            field_index: 2,
            field: cloned_field,
        },
        AssertGridMetaPad,
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_field() {
    let text_field = create_text_field();
    let scripts = vec![
        CreateField {
            field: text_field.clone(),
        },
        AssertFieldCount(3),
        DeleteField { field: text_field },
        AssertFieldCount(2),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_block() {
    let grid_block = GridBlock::new();
    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: grid_block },
        AssertBlockCount(2),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_block() {
    let grid_block = GridBlock::new();
    let mut cloned_grid_block = grid_block.clone();
    let change = GridBlockChangeset {
        block_id: grid_block.id.clone(),
        start_row_index: Some(2),
        row_count: Some(10),
    };

    cloned_grid_block.start_row_index = 2;
    cloned_grid_block.row_count = 10;

    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: grid_block },
        UpdateBlock { change },
        AssertBlockCount(2),
        AssertBlockEqual {
            block_index: 1,
            block: cloned_grid_block,
        },
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_row() {
    let scripts = vec![AssertRowCount(3), CreateRow, CreateRow, AssertRowCount(5)];
    GridEditorTest::new().await.run_scripts(scripts).await;
}
