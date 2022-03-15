use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid::services::cell::*;
use flowy_grid::services::row::{deserialize_cell_data, serialize_cell_data, CellDataSerde, CreateRowContextBuilder};
use flowy_grid_data_model::entities::{FieldChangeset, FieldType, GridBlock, GridBlockChangeset, RowMetaChangeset};

#[tokio::test]
async fn grid_create_field() {
    let mut test = GridEditorTest::new().await;
    let text_field = create_text_field();
    let single_select_field = create_single_select_field();

    let scripts = vec![
        CreateField {
            field_meta: text_field.clone(),
        },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta: text_field,
        },
    ];
    test.run_scripts(scripts).await;

    let scripts = vec![
        CreateField {
            field_meta: single_select_field.clone(),
        },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta: single_select_field,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_duplicate_field() {
    let mut test = GridEditorTest::new().await;
    let text_field = create_text_field();
    let field_count = test.field_count;
    let expected_field_count = field_count + 1;
    let scripts = vec![
        CreateField {
            field_meta: text_field.clone(),
        },
        CreateField {
            field_meta: text_field.clone(),
        },
        AssertFieldCount(expected_field_count),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
    let mut test = GridEditorTest::new().await;
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
            field_meta: single_select_field.clone(),
        },
        UpdateField { changeset },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta: single_select_field,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field() {
    let mut test = GridEditorTest::new().await;
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
            field_meta: single_select_field.clone(),
        },
        UpdateField { changeset },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta: cloned_field,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_field() {
    let mut test = GridEditorTest::new().await;
    let expected_field_count = test.field_count;
    let text_field = create_text_field();
    let scripts = vec![
        CreateField {
            field_meta: text_field.clone(),
        },
        DeleteField { field_meta: text_field },
        AssertFieldCount(expected_field_count),
    ];
    test.run_scripts(scripts).await;
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
    let create_row_context = CreateRowContextBuilder::new(&test.field_metas).build();
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
    let context = CreateRowContextBuilder::new(&test.field_metas).build();
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
    let context_1 = CreateRowContextBuilder::new(&test.field_metas).build();
    let context_2 = CreateRowContextBuilder::new(&test.field_metas).build();
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
    let mut builder = CreateRowContextBuilder::new(&test.field_metas);
    for field in &test.field_metas {
        match field.field_type {
            FieldType::RichText => {
                let data = serialize_cell_data("hello world", field).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::Number => {
                let data = serialize_cell_data("¥18,443", field).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::DateTime => {
                let data = serialize_cell_data("1647251762", field).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::SingleSelect => {
                let description = SingleSelectDescription::from(field);
                let options = description.options.first().unwrap();

                let data = description.serialize_cell_data(&options.id).unwrap();
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
                let data = description.serialize_cell_data(&options).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
            FieldType::Checkbox => {
                let data = serialize_cell_data("false", field).unwrap();
                builder = builder.add_cell(&field.id, data);
            }
        }
    }
    let context = builder.build();
    let scripts = vec![AssertRowCount(3), CreateRow { context }, AssertGridMetaPad];
    test.run_scripts(scripts).await;
}
