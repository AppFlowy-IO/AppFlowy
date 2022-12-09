use crate::revision_test::script::RevisionScript::*;
use crate::revision_test::script::{InvalidRevisionObject, RevisionTest};

#[tokio::test]
async fn revision_write_to_disk_test() {
    let test = RevisionTest::new_with_configuration(2).await;
    test.run_script(AddLocalRevision {
        content: "123".to_string(),
    })
    .await;

    test.run_scripts(vec![
        AssertNumberOfRevisionsInDisk { num: 0 },
        WaitWhenWriteToDisk,
        AssertNumberOfRevisionsInDisk { num: 1 },
    ])
    .await;
}

#[tokio::test]
async fn revision_write_to_disk_with_merge_test() {
    let test = RevisionTest::new_with_configuration(100).await;
    for i in 0..1000 {
        test.run_script(AddLocalRevision {
            content: format!("{}", i),
        })
        .await;
    }

    test.run_scripts(vec![
        AssertNumberOfRevisionsInDisk { num: 0 },
        AssertNumberOfSyncRevisions { num: 10 },
        WaitWhenWriteToDisk,
        AssertNumberOfRevisionsInDisk { num: 10 },
    ])
    .await;
}

#[tokio::test]
async fn revision_read_from_disk_test() {
    let test = RevisionTest::new_with_configuration(2).await;
    test.run_scripts(vec![
        AddLocalRevision {
            content: "123".to_string(),
        },
        AssertNumberOfRevisionsInDisk { num: 0 },
        WaitWhenWriteToDisk,
        AssertNumberOfRevisionsInDisk { num: 1 },
    ])
    .await;

    let test = RevisionTest::new_with_other(test).await;
    test.run_scripts(vec![
        AssertNextSyncRevisionId { rev_id: Some(1) },
        AddLocalRevision {
            content: "456".to_string(),
        },
        AckRevision { rev_id: 1 },
        AssertNextSyncRevisionId { rev_id: Some(2) },
    ])
    .await;
}

#[tokio::test]
async fn revision_read_from_disk_with_invalid_record_test() {
    let test = RevisionTest::new_with_configuration(2).await;
    test.run_scripts(vec![AddLocalRevision {
        content: "123".to_string(),
    }])
    .await;

    test.run_scripts(vec![
        AddInvalidLocalRevision {
            bytes: InvalidRevisionObject::new().to_bytes(),
        },
        WaitWhenWriteToDisk,
    ])
    .await;

    let test = RevisionTest::new_with_other(test).await;
    test.run_scripts(vec![AssertNextSyncRevisionContent {
        expected: "123".to_string(),
    }])
    .await;
}
