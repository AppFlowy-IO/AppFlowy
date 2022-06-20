use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use chrono::NaiveDateTime;
use flowy_grid::services::field::{
    DateCellData, MultiSelectTypeOption, SingleSelectTypeOption, SELECTION_IDS_SEPARATOR,
};
use flowy_grid::services::row::{decode_cell_data_from_type_option_cell_data, CreateRowRevisionBuilder};
use flowy_grid_data_model::entities::FieldType;
use flowy_grid_data_model::revision::RowMetaChangeset;

#[tokio::test]
async fn grid_create_row_count_test() {
    let test = GridEditorTest::new().await;
    let create_row_context = CreateRowRevisionBuilder::new(&test.field_revs).build();
    let scripts = vec![
        AssertRowCount(3),
        CreateEmptyRow,
        CreateEmptyRow,
        CreateRow {
            context: create_row_context,
        },
        AssertRowCount(6),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_row() {
    let mut test = GridEditorTest::new().await;
    let context = CreateRowRevisionBuilder::new(&test.field_revs).build();
    let changeset = RowMetaChangeset {
        row_id: context.row_id.clone(),
        height: None,
        visibility: None,
        cell_by_field_id: Default::default(),
    };

    let scripts = vec![AssertRowCount(3), CreateRow { context }, UpdateRow { changeset }];
    test.run_scripts(scripts).await;

    let expected_row = (&*test.row_revs.last().cloned().unwrap()).clone();
    let scripts = vec![AssertRow { expected_row }, AssertRowCount(4)];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_row() {
    let mut test = GridEditorTest::new().await;
    let context_1 = CreateRowRevisionBuilder::new(&test.field_revs).build();
    let context_2 = CreateRowRevisionBuilder::new(&test.field_revs).build();
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
            FieldType::URL => {
                builder.add_cell(&field.id, "1".to_string()).unwrap();
            }
        }
    }
    let context = builder.build();
    let scripts = vec![CreateRow { context }, AssertGridRevisionPad];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_date_cell_test() {
    let mut test = GridEditorTest::new().await;
    let mut builder = CreateRowRevisionBuilder::new(&test.field_revs);
    let mut date_field = None;
    let timestamp = 1647390674;
    for field in &test.field_revs {
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
        decode_cell_data_from_type_option_cell_data(cell_data.data.clone(), &date_field, &date_field.field_type)
            .parse::<DateCellData>()
            .unwrap()
            .date,
        "2022/03/16",
    );
    let scripts = vec![CreateRow { context }];
    test.run_scripts(scripts).await;
}
