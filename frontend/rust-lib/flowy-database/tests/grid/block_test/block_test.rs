use crate::grid::block_test::script::DatabaseRowTest;
use crate::grid::block_test::script::RowScript::*;

use grid_model::{GridBlockMetaRevision, GridBlockMetaRevisionChangeset};

#[tokio::test]
async fn grid_create_block() {
    let block_meta_rev = GridBlockMetaRevision::new();
    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: block_meta_rev },
        AssertBlockCount(2),
    ];
    DatabaseRowTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_block() {
    let block_meta_rev = GridBlockMetaRevision::new();
    let mut cloned_grid_block = block_meta_rev.clone();
    let changeset = GridBlockMetaRevisionChangeset {
        block_id: block_meta_rev.block_id.clone(),
        start_row_index: Some(2),
        row_count: Some(10),
    };

    cloned_grid_block.start_row_index = 2;
    cloned_grid_block.row_count = 10;

    let scripts = vec![
        AssertBlockCount(1),
        CreateBlock { block: block_meta_rev },
        UpdateBlock { changeset },
        AssertBlockCount(2),
        AssertBlockEqual {
            block_index: 1,
            block: cloned_grid_block,
        },
    ];
    DatabaseRowTest::new().await.run_scripts(scripts).await;
}
