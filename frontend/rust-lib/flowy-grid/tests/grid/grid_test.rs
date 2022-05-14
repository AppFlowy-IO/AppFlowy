use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use chrono::NaiveDateTime;
use flowy_grid::services::field::{
    DateCellContentChangeset, MultiSelectTypeOption, SelectOption, SelectOptionCellContentChangeset,
    SingleSelectTypeOption, SELECTION_IDS_SEPARATOR,
};
use flowy_grid::services::row::{decode_cell_data, CreateRowMetaBuilder};
use flowy_grid_data_model::entities::{
    CellChangeset, FieldChangesetParams, FieldType, GridBlockMeta, GridBlockMetaChangeset, RowMetaChangeset,
    TypeOptionDataEntry,
};

#[tokio::test]
async fn grid_create_field() {
    let mut test = GridEditorTest::new().await;
    let (text_field_params, text_field_meta) = create_text_field(&test.grid_id);
    let (single_select_params, single_select_field) = create_single_select_field(&test.grid_id);
    let scripts = vec![
        CreateField {
            params: text_field_params,
        },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta: text_field_meta,
        },
    ];
    test.run_scripts(scripts).await;

    let scripts = vec![
        CreateField {
            params: single_select_params,
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
    let (params, _) = create_text_field(&test.grid_id);
    let field_count = test.field_count;
    let expected_field_count = field_count + 1;
    let scripts = vec![
        CreateField { params: params.clone() },
        CreateField { params },
        AssertFieldCount(expected_field_count),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
    let mut test = GridEditorTest::new().await;
    let (params, field_meta) = create_single_select_field(&test.grid_id);
    let changeset = FieldChangesetParams {
        field_id: field_meta.id.clone(),
        grid_id: test.grid_id.clone(),
        ..Default::default()
    };

    let scripts = vec![
        CreateField { params },
        UpdateField { changeset },
        AssertFieldEqual {
            field_index: test.field_count,
            field_meta,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field() {
    let mut test = GridEditorTest::new().await;
    let (single_select_params, single_select_field) = create_single_select_field(&test.grid_id);
    let mut cloned_field = single_select_field.clone();

    let mut single_select_type_option = SingleSelectTypeOption::from(&single_select_field);
    single_select_type_option.options.push(SelectOption::new("Unknown"));
    let changeset = FieldChangesetParams {
        field_id: single_select_field.id.clone(),
        grid_id: test.grid_id.clone(),
        frozen: Some(true),
        width: Some(1000),
        type_option_data: Some(single_select_type_option.protobuf_bytes().to_vec()),
        ..Default::default()
    };

    cloned_field.frozen = true;
    cloned_field.width = 1000;
    cloned_field.insert_type_option_entry(&single_select_type_option);

    let scripts = vec![
        CreateField {
            params: single_select_params,
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
    let (text_params, text_field) = create_text_field(&test.grid_id);
    let scripts = vec![
        CreateField { params: text_params },
        DeleteField { field_meta: text_field },
        AssertFieldCount(expected_field_count),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_block() {
    let grid_block = GridBlockMeta::new();
    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: grid_block },
        AssertBlockCount(2),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_block() {
    let grid_block = GridBlockMeta::new();
    let mut cloned_grid_block = grid_block.clone();
    let changeset = GridBlockMetaChangeset {
        block_id: grid_block.block_id.clone(),
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
    let create_row_context = CreateRowMetaBuilder::new(&test.field_metas).build();
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
    let context = CreateRowMetaBuilder::new(&test.field_metas).build();
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
    let context_1 = CreateRowMetaBuilder::new(&test.field_metas).build();
    let context_2 = CreateRowMetaBuilder::new(&test.field_metas).build();
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
    let mut builder = CreateRowMetaBuilder::new(&test.field_metas);
    for field in &test.field_metas {
        match field.field_type {
            FieldType::RichText => {
                builder.add_cell(&field.id, "hello world".to_owned()).unwrap();
            }
            FieldType::Number => {
                builder.add_cell(&field.id, "18,443".to_owned()).unwrap();
            }
            FieldType::DateTime => {
                builder
                    .add_cell(&field.id, make_date_cell_string("1647251762"))
                    .unwrap();
            }
            FieldType::SingleSelect => {
                let type_option = SingleSelectTypeOption::from(field);
                let option = type_option.options.first().unwrap();
                builder.add_select_option_cell(&field.id, option.id.clone()).unwrap();
            }
            FieldType::MultiSelect => {
                let type_option = MultiSelectTypeOption::from(field);
                let ops_ids = type_option
                    .options
                    .iter()
                    .map(|option| option.id.clone())
                    .collect::<Vec<_>>()
                    .join(SELECTION_IDS_SEPARATOR);
                builder.add_select_option_cell(&field.id, ops_ids).unwrap();
            }
            FieldType::Checkbox => {
                builder.add_cell(&field.id, "false".to_string()).unwrap();
            }
        }
    }
    let context = builder.build();
    let scripts = vec![CreateRow { context }, AssertGridMetaPad];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_date_cell_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = CreateRowMetaBuilder::new(&test.field_metas);
    let mut date_field = None;
    let timestamp = 1647390674;
    for field in &test.field_metas {
        if field.field_type == FieldType::DateTime {
            date_field = Some(field.clone());
            NaiveDateTime::from_timestamp(123, 0);
            // The data should not be empty
            assert!(builder.add_cell(&field.id, "".to_string()).is_err());
            assert!(builder.add_cell(&field.id, make_date_cell_string("123")).is_ok());
            assert!(builder
                .add_cell(&field.id, make_date_cell_string(&timestamp.to_string()))
                .is_ok());
        }
    }
    let context = builder.build();
    let date_field = date_field.unwrap();
    let cell_data = context.cell_by_field_id.get(&date_field.id).unwrap().clone();
    assert_eq!(
        decode_cell_data(cell_data.data.clone(), &date_field, &date_field.field_type)
            .unwrap()
            .split()
            .1,
        "2022/03/16",
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

    let block_id = &grid_blocks.first().unwrap().block_id;
    let mut scripts = vec![];
    for (index, row_meta) in row_metas.iter().enumerate() {
        for field_meta in field_metas {
            if index == 0 {
                let data = match field_meta.field_type {
                    FieldType::RichText => "".to_string(),
                    FieldType::Number => "123".to_string(),
                    FieldType::DateTime => make_date_cell_string("123"),
                    FieldType::SingleSelect => {
                        let type_option = SingleSelectTypeOption::from(field_meta);
                        SelectOptionCellContentChangeset::from_insert(&type_option.options.first().unwrap().id).to_str()
                    }
                    FieldType::MultiSelect => {
                        let type_option = MultiSelectTypeOption::from(field_meta);
                        SelectOptionCellContentChangeset::from_insert(&type_option.options.first().unwrap().id).to_str()
                    }
                    FieldType::Checkbox => "1".to_string(),
                };

                scripts.push(UpdateCell {
                    changeset: CellChangeset {
                        grid_id: block_id.to_string(),
                        row_id: row_meta.id.clone(),
                        field_id: field_meta.id.clone(),
                        cell_content_changeset: Some(data),
                    },
                    is_err: false,
                });
            }

            if index == 1 {
                let (data, is_err) = match field_meta.field_type {
                    FieldType::RichText => ("1".to_string().repeat(10001), true),
                    FieldType::Number => ("abc".to_string(), true),
                    FieldType::DateTime => ("abc".to_string(), true),
                    FieldType::SingleSelect => (SelectOptionCellContentChangeset::from_insert("abc").to_str(), false),
                    FieldType::MultiSelect => (SelectOptionCellContentChangeset::from_insert("abc").to_str(), false),
                    FieldType::Checkbox => ("2".to_string(), false),
                };

                scripts.push(UpdateCell {
                    changeset: CellChangeset {
                        grid_id: block_id.to_string(),
                        row_id: row_meta.id.clone(),
                        field_id: field_meta.id.clone(),
                        cell_content_changeset: Some(data),
                    },
                    is_err,
                });
            }
        }
    }

    test.run_scripts(scripts).await;
}

fn make_date_cell_string(s: &str) -> String {
    serde_json::to_string(&DateCellContentChangeset {
        date: Some(s.to_string()),
        time: None,
    })
    .unwrap()
}
