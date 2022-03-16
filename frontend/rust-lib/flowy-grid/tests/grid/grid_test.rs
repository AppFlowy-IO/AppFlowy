use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use chrono::NaiveDateTime;
use flowy_grid::services::cell::*;
use flowy_grid::services::row::{deserialize_cell_data, serialize_cell_data, CellDataSerde, RowMetaContextBuilder};
use flowy_grid_data_model::entities::{
    CellMetaChangeset, FieldChangeset, FieldType, GridBlock, GridBlockChangeset, RowMetaChangeset,
};

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
    let create_row_context = RowMetaContextBuilder::new(&test.field_metas).build();
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
    let context = RowMetaContextBuilder::new(&test.field_metas).build();
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
    let context_1 = RowMetaContextBuilder::new(&test.field_metas).build();
    let context_2 = RowMetaContextBuilder::new(&test.field_metas).build();
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
async fn grid_row_add_cells_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = RowMetaContextBuilder::new(&test.field_metas);
    for field in &test.field_metas {
        match field.field_type {
            FieldType::RichText => {
                let data = serialize_cell_data("hello world", field).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
            FieldType::Number => {
                let data = serialize_cell_data("¥18,443", field).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
            FieldType::DateTime => {
                let data = serialize_cell_data("1647251762", field).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
            FieldType::SingleSelect => {
                let description = SingleSelectDescription::from(field);
                let options = description.options.first().unwrap();
                let data = description.serialize_cell_data(&options.id).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
            FieldType::MultiSelect => {
                let description = MultiSelectDescription::from(field);
                let options = description
                    .options
                    .iter()
                    .map(|option| option.id.clone())
                    .collect::<Vec<_>>()
                    .join(SELECTION_IDS_SEPARATOR);
                let data = description.serialize_cell_data(&options).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
            FieldType::Checkbox => {
                let data = serialize_cell_data("false", field).unwrap();
                builder.add_cell(&field.id, data).unwrap();
            }
        }
    }
    let context = builder.build();
    let scripts = vec![CreateRow { context }, AssertGridMetaPad];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_selection_cell_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = RowMetaContextBuilder::new(&test.field_metas);
    let uuid = uuid::Uuid::new_v4().to_string();
    let mut single_select_field_id = "".to_string();
    let mut multi_select_field_id = "".to_string();
    for field in &test.field_metas {
        match field.field_type {
            FieldType::SingleSelect => {
                single_select_field_id = field.id.clone();
                // The element must be parsed as uuid
                assert!(builder.add_cell(&field.id, "data".to_owned()).is_err());
                // // The data should not be empty
                assert!(builder.add_cell(&field.id, "".to_owned()).is_err());
                // The element must be parsed as uuid
                assert!(builder.add_cell(&field.id, "1,2,3".to_owned()).is_err(),);
                // The separator must be comma
                assert!(builder.add_cell(&field.id, format!("{}. {}", &uuid, &uuid),).is_err());
                //

                assert!(builder.add_cell(&field.id, uuid.clone()).is_ok());
                assert!(builder.add_cell(&field.id, format!("{},   {}", &uuid, &uuid)).is_ok());
            }
            FieldType::MultiSelect => {
                multi_select_field_id = field.id.clone();
                assert!(builder.add_cell(&field.id, format!("{},   {}", &uuid, &uuid)).is_ok());
            }
            _ => {}
        }
    }
    let context = builder.build();
    assert_eq!(
        &context
            .cell_by_field_id
            .get(&single_select_field_id)
            .as_ref()
            .unwrap()
            .data,
        &uuid
    );
    assert_eq!(
        context
            .cell_by_field_id
            .get(&multi_select_field_id)
            .as_ref()
            .unwrap()
            .data,
        format!("{},{}", &uuid, &uuid)
    );

    let scripts = vec![CreateRow { context }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_date_cell_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = RowMetaContextBuilder::new(&test.field_metas);
    let mut date_field = None;
    let timestamp = 1647390674;
    for field in &test.field_metas {
        if field.field_type == FieldType::DateTime {
            date_field = Some(field.clone());
            NaiveDateTime::from_timestamp(123, 0);
            // The data should not be empty
            assert!(builder.add_cell(&field.id, "".to_owned()).is_err());

            assert!(builder.add_cell(&field.id, "123".to_owned()).is_ok());
            assert!(builder.add_cell(&field.id, format!("{}", timestamp)).is_ok());
        }
    }
    let context = builder.build();
    let date_field = date_field.unwrap();
    let cell_data = context.cell_by_field_id.get(&date_field.id).unwrap().clone();
    assert_eq!(
        deserialize_cell_data(cell_data.data.clone(), &date_field).unwrap(),
        "2022/03/16 08:31",
    );
    let scripts = vec![CreateRow { context }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_cell_update() {
    let mut test = GridEditorTest::new().await;
    let field_metas = &test.field_metas;
    let row_metas = &test.row_metas;
    let grid_blocks = &test.grid_blocks;
    assert_eq!(row_metas.len(), 3);
    assert_eq!(grid_blocks.len(), 1);

    let block_id = &grid_blocks.first().unwrap().id;
    let mut scripts = vec![];
    for (index, row_meta) in row_metas.iter().enumerate() {
        for field_meta in field_metas {
            if index == 0 {
                let data = match field_meta.field_type {
                    FieldType::RichText => "".to_string(),
                    FieldType::Number => "123".to_string(),
                    FieldType::DateTime => "123".to_string(),
                    FieldType::SingleSelect => {
                        let description = SingleSelectDescription::from(field_meta);
                        description.options.first().unwrap().id.clone()
                    }
                    FieldType::MultiSelect => {
                        let description = MultiSelectDescription::from(field_meta);
                        description.options.first().unwrap().id.clone()
                    }
                    FieldType::Checkbox => "1".to_string(),
                };

                scripts.push(UpdateCell {
                    changeset: CellMetaChangeset {
                        grid_id: block_id.to_string(),
                        row_id: row_meta.id.clone(),
                        field_id: field_meta.id.clone(),
                        data: Some(data),
                    },
                    is_err: false,
                });
            }

            if index == 1 {
                let (data, is_err) = match field_meta.field_type {
                    FieldType::RichText => ("1".to_string().repeat(10001), true),
                    FieldType::Number => ("abc".to_string(), true),
                    FieldType::DateTime => ("abc".to_string(), true),
                    FieldType::SingleSelect => ("abc".to_string(), true),
                    FieldType::MultiSelect => ("abc".to_string(), true),
                    FieldType::Checkbox => ("2".to_string(), false),
                };

                scripts.push(UpdateCell {
                    changeset: CellMetaChangeset {
                        grid_id: block_id.to_string(),
                        row_id: row_meta.id.clone(),
                        field_id: field_meta.id.clone(),
                        data: Some(data),
                    },
                    is_err,
                });
            }
        }
    }

    test.run_scripts(scripts).await;
}
