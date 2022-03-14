use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid::services::cell::*;
use flowy_grid::services::row::{CreateRowContextBuilder, StringifyCellData};
use flowy_grid_data_model::entities::{FieldChangeset, FieldType, GridBlock, GridBlockChangeset, RowMetaChangeset};

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
    let changeset = FieldChangeset {
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
        UpdateField { changeset },
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

    let changeset = FieldChangeset {
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
        UpdateField { changeset },
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
    let changeset = GridBlockChangeset {
        block_id: grid_block.id.clone(),
        start_row_index: Some(2),
        row_count: Some(10),
    };

    cloned_grid_block.start_row_index = 2;
    cloned_grid_block.row_count = 10;

    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: grid_block },
        UpdateBlock { changeset },
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
    let scripts = vec![AssertRowCount(3), CreateEmptyRow, CreateEmptyRow, AssertRowCount(5)];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_row2() {
    let mut test = GridEditorTest::new().await;
    let create_row_context = CreateRowContextBuilder::new(&test.fields).build();
    let scripts = vec![
        AssertRowCount(3),
        CreateRow {
            context: create_row_context,
        },
        AssertRowCount(4),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_row() {
    let mut test = GridEditorTest::new().await;
    let context = CreateRowContextBuilder::new(&test.fields).build();
    let changeset = RowMetaChangeset {
        row_id: context.row_id.clone(),
        height: None,
        visibility: None,
        cell_by_field_id: Default::default(),
    };

    let scripts = vec![
        AssertRowCount(3),
        CreateRow { context },
        UpdateRow {
            changeset: changeset.clone(),
        },
        AssertRow { changeset },
        AssertRowCount(4),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_row() {
    let mut test = GridEditorTest::new().await;
    let context_1 = CreateRowContextBuilder::new(&test.fields).build();
    let context_2 = CreateRowContextBuilder::new(&test.fields).build();
    let row_ids = vec![context_1.row_id.clone(), context_2.row_id.clone()];
    let scripts = vec![
        AssertRowCount(3),
        CreateRow { context: context_1 },
        CreateRow { context: context_2 },
        AssertBlockCount(1),
        AssertBlock {
            block_index: 0,
            row_count: 5,
            start_row_index: 0,
        },
        DeleteRow { row_ids },
        AssertBlock {
            block_index: 0,
            row_count: 3,
            start_row_index: 0,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_cell() {
    let mut test = GridEditorTest::new().await;
    let mut builder = CreateRowContextBuilder::new(&test.fields);
    for field in &test.fields {
        match field.field_type {
            FieldType::RichText => {
                builder = builder.add_cell(&field.id, "hello world".to_owned());
            }
            FieldType::Number => {
                let description = NumberDescription::from(field);
                let data = description.str_to_cell_data("¥18,443").unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::DateTime => {
                let description = DateDescription::from(field);
                let data = description.str_to_cell_data("1647251762").unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::SingleSelect => {
                let description = SingleSelectDescription::from(field);
                let options = description.options.first().unwrap();
                let data = description.str_to_cell_data(&options.id).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::MultiSelect => {
                let description = MultiSelectDescription::from(field);
                let options = description
                    .options
                    .iter()
                    .map(|option| option.id.clone())
                    .collect::<Vec<_>>()
                    .join(",");
                let data = description.str_to_cell_data(&options).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::Checkbox => {
                let description = CheckboxDescription::from(field);
                let data = description.str_to_cell_data("false").unwrap();
                builder = builder.add_cell(&field.id, data);
            }
        }
    }
    let context = builder.build();
    let scripts = vec![AssertRowCount(3), CreateRow { context }, AssertGridMetaPad];
    test.run_scripts(scripts).await;
}
