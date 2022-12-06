use crate::grid::field_test::util::create_text_field;
use crate::grid::snapshot_test::script::{GridSnapshotTest, SnapshotScript::*};
use flowy_sync::client_grid::{GridOperations, GridRevisionPad};

#[tokio::test]
async fn snapshot_create_test() {
    let mut test = GridSnapshotTest::new().await;
    let (_, field_rev) = create_text_field(&test.grid_id());
    let scripts = vec![CreateField { field_rev }, WriteSnapshot];
    test.run_scripts(scripts).await;

    let snapshot = test.current_snapshot.clone().unwrap();
    let content = test.grid_pad().await.json_str().unwrap();
    test.run_scripts(vec![AssertSnapshotContent {
        snapshot,
        expected: content,
    }])
    .await;
}

#[tokio::test]
async fn snapshot_multi_version_test() {
    let mut test = GridSnapshotTest::new().await;
    let original_content = test.grid_pad().await.json_str().unwrap();

    // Create a field
    let (_, field_rev) = create_text_field(&test.grid_id());
    let scripts = vec![
        CreateField {
            field_rev: field_rev.clone(),
        },
        WriteSnapshot,
    ];
    test.run_scripts(scripts).await;

    // Delete a field
    let scripts = vec![DeleteField { field_rev }, WriteSnapshot];
    test.run_scripts(scripts).await;

    // The latest snapshot will be the same as the original content.
    test.run_scripts(vec![AssertSnapshotContent {
        snapshot: test.get_latest_snapshot().await.unwrap(),
        expected: original_content,
    }])
    .await;
}
