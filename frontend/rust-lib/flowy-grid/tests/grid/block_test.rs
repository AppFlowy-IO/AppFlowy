use crate::grid::script::EditorScript::*;
use crate::grid::script::*;
use flowy_grid_data_model::revision::{GridBlockRevision, GridBlockRevisionChangeset};

#[tokio::test]
async fn grid_create_block() {
    let grid_block = GridBlockRevision::new();
    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: grid_block },
        AssertBlockCount(2),
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_block() {
    let grid_block = GridBlockRevision::new();
    let mut cloned_grid_block = grid_block.clone();
    let changeset = GridBlockRevisionChangeset {
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
