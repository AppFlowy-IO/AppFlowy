use crate::grid::field_util::*;
use crate::grid::row_util::GridRowTestBuilder;
use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use chrono::NaiveDateTime;
use flowy_grid::entities::FieldType;
use flowy_grid::services::field::select_option::SELECTION_IDS_SEPARATOR;
use flowy_grid::services::field::{DateCellData, MultiSelectTypeOption, SingleSelectTypeOption};
use flowy_grid::services::row::{decode_any_cell_data, CreateRowRevisionBuilder};
use flowy_grid_data_model::revision::RowMetaChangeset;

#[tokio::test]
async fn grid_create_row_count_test() {
    let test = GridEditorTest::new().await;
    let scripts = vec![
        AssertRowCount(3),
        CreateEmptyRow,
        CreateEmptyRow,
        CreateRow {
            payload: GridRowTestBuilder::new(&test).build(),
        },
        AssertRowCount(6),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_row() {
    let mut test = GridEditorTest::new().await;
    let payload = GridRowTestBuilder::new(&test).build();
    let changeset = RowMetaChangeset {
        row_id: payload.row_id.clone(),
        height: None,
        visibility: None,
        cell_by_field_id: Default::default(),
    };

    let scripts = vec![AssertRowCount(3), CreateRow { payload }, UpdateRow { changeset }];
    test.run_scripts(scripts).await;

    let expected_row = (&*test.row_revs.last().cloned().unwrap()).clone();
    let scripts = vec![AssertRow { expected_row }, AssertRowCount(4)];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_row() {
    let mut test = GridEditorTest::new().await;
    let payload1 = GridRowTestBuilder::new(&test).build();
    let payload2 = GridRowTestBuilder::new(&test).build();
    let row_ids = vec![payload1.row_id.clone(), payload2.row_id.clone()];
    let scripts = vec![
        AssertRowCount(3),
        CreateRow { payload: payload1 },
        CreateRow { payload: payload2 },
        AssertBlockCount(1),
        AssertBlock {
            block_index: 0,
            row_count: 5,
            start_row_index: 0,
        },
        DeleteRows { row_ids },
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
    let mut builder = CreateRowRevisionBuilder::new(&test.field_revs);
    for field in &test.field_revs {
        let field_type: FieldType = field.field_type_rev.into();
        match field_type {
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
            FieldType::URL => {
                builder.add_cell(&field.id, "1".to_string()).unwrap();
            }
        }
    }
    let context = builder.build();
    let scripts = vec![CreateRow { payload: context }, AssertGridRevisionPad];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_date_cell_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = CreateRowRevisionBuilder::new(&test.field_revs);
    let mut date_field = None;
    let timestamp = 1647390674;
    for field in &test.field_revs {
        let field_type: FieldType = field.field_type_rev.into();
        if field_type == FieldType::DateTime {
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
    let cell_rev = context.cell_by_field_id.get(&date_field.id).unwrap();
    assert_eq!(
        decode_any_cell_data(cell_rev, &date_field)
            .parse::<DateCellData>()
            .unwrap()
            .date,
        "2022/03/16",
    );
    let scripts = vec![CreateRow { payload: context }];
    test.run_scripts(scripts).await;
}
