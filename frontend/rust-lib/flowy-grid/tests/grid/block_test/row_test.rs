use crate::grid::block_test::script::RowScript::*;
use crate::grid::block_test::script::{CreateRowScriptBuilder, GridRowTest};
use crate::grid::grid_editor::{COMPLETED, FACEBOOK, GOOGLE, PAUSED, TWITTER};
use flowy_grid::entities::FieldType;
use flowy_grid::services::field::{SELECTION_IDS_SEPARATOR, UNCHECK};
use grid_rev_model::RowChangeset;

#[tokio::test]
async fn grid_create_row_count_test() {
    let mut test = GridRowTest::new().await;
    let scripts = vec![
        AssertRowCount(6),
        CreateEmptyRow,
        CreateEmptyRow,
        CreateRow {
            row_rev: test.row_builder().build(),
        },
        AssertRowCount(9),
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_row() {
    let mut test = GridRowTest::new().await;
    let row_rev = test.row_builder().build();
    let changeset = RowChangeset {
        row_id: row_rev.id.clone(),
        height: None,
        visibility: None,
        cell_by_field_id: Default::default(),
    };
    let row_count = test.row_revs.len();
    let scripts = vec![CreateRow { row_rev }, UpdateRow { changeset }];
    test.run_scripts(scripts).await;

    let expected_row = test.last_row().unwrap();
    let scripts = vec![AssertRow { expected_row }, AssertRowCount(row_count + 1)];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_row() {
    let mut test = GridRowTest::new().await;
    let row_1 = test.row_builder().build();
    let row_2 = test.row_builder().build();
    let row_ids = vec![row_1.id.clone(), row_2.id.clone()];
    let row_count = test.row_revs.len() as i32;
    let scripts = vec![
        CreateRow { row_rev: row_1 },
        CreateRow { row_rev: row_2 },
        AssertBlockCount(1),
        AssertBlock {
            block_index: 0,
            row_count: row_count + 2,
            start_row_index: 0,
        },
        DeleteRows { row_ids },
        AssertBlock {
            block_index: 0,
            row_count,
            start_row_index: 0,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_add_cells_test() {
    let mut test = GridRowTest::new().await;
    let mut builder = CreateRowScriptBuilder::new(&test);
    builder.insert(FieldType::RichText, "hello world", "hello world");
    builder.insert(FieldType::DateTime, "1647251762", "2022/03/14");
    builder.insert(FieldType::Number, "18,443", "$18,443.00");
    builder.insert(FieldType::Checkbox, "false", UNCHECK);
    builder.insert(FieldType::URL, "https://appflowy.io", "https://appflowy.io");
    builder.insert_single_select_cell(|mut options| options.remove(0), COMPLETED);
    builder.insert_multi_select_cell(
        |options| options,
        &vec![GOOGLE, FACEBOOK, TWITTER].join(SELECTION_IDS_SEPARATOR),
    );
    let scripts = builder.build();
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_insert_number_test() {
    let mut test = GridRowTest::new().await;
    for (val, expected) in &[("1647251762", "2022/03/14"), ("2022/03/14", ""), ("", "")] {
        let mut builder = CreateRowScriptBuilder::new(&test);
        builder.insert(FieldType::DateTime, val, expected);
        let scripts = builder.build();
        test.run_scripts(scripts).await;
    }
}

#[tokio::test]
async fn grid_row_insert_date_test() {
    let mut test = GridRowTest::new().await;
    for (val, expected) in &[
        ("18,443", "$18,443.00"),
        ("0", "$0.00"),
        ("100000", "$100,000.00"),
        ("$100,000.00", "$100,000.00"),
        ("", ""),
    ] {
        let mut builder = CreateRowScriptBuilder::new(&test);
        builder.insert(FieldType::Number, val, expected);
        let scripts = builder.build();
        test.run_scripts(scripts).await;
    }
}
#[tokio::test]
async fn grid_row_insert_single_select_test() {
    let mut test = GridRowTest::new().await;
    let mut builder = CreateRowScriptBuilder::new(&test);
    builder.insert_single_select_cell(|mut options| options.pop().unwrap(), PAUSED);
    let scripts = builder.build();
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_row_insert_multi_select_test() {
    let mut test = GridRowTest::new().await;
    let mut builder = CreateRowScriptBuilder::new(&test);
    builder.insert_multi_select_cell(
        |mut options| {
            options.remove(0);
            options
        },
        &vec![FACEBOOK, TWITTER].join(SELECTION_IDS_SEPARATOR),
    );
    let scripts = builder.build();
    test.run_scripts(scripts).await;
}
