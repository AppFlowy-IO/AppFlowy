use crate::revision_test::script::RevisionScript::*;
use crate::revision_test::script::{InvalidRevisionObject, RevisionTest};
use flowy_revision::REVISION_WRITE_INTERVAL_IN_MILLIS;

#[tokio::test]
async fn revision_write_to_disk_test() {
    let test = RevisionTest::new_with_configuration(2).await;
    let (base_rev_id, rev_id) = test.next_rev_id_pair();

    test.run_script(AddLocalRevision {
        content: "123".to_string(),
        base_rev_id,
        rev_id,
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
        let (base_rev_id, rev_id) = test.next_rev_id_pair();
        test.run_script(AddLocalRevision {
            content: format!("{}", i),
            base_rev_id,
            rev_id,
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
    let (base_rev_id, rev_id) = test.next_rev_id_pair();
    test.run_scripts(vec![
        AddLocalRevision {
            content: "123".to_string(),
            base_rev_id,
            rev_id,
        },
        AssertNumberOfRevisionsInDisk { num: 0 },
        WaitWhenWriteToDisk,
        AssertNumberOfRevisionsInDisk { num: 1 },
    ])
    .await;

    let test = RevisionTest::new_with_other(test).await;
    let (base_rev_id, rev_id) = test.next_rev_id_pair();
    test.run_scripts(vec![
        AssertNextSyncRevisionId { rev_id: Some(1) },
        AddLocalRevision {
            content: "456".to_string(),
            base_rev_id,
            rev_id: rev_id.clone(),
        },
        AckRevision { rev_id: 1 },
        AssertNextSyncRevisionId { rev_id: Some(rev_id) },
    ])
    .await;
}

#[tokio::test]
#[should_panic]
async fn revision_read_from_disk_with_invalid_record_test() {
    let test = RevisionTest::new_with_configuration(2).await;
    let (base_rev_id, rev_id) = test.next_rev_id_pair();
    test.run_script(AddLocalRevision {
        content: "123".to_string(),
        base_rev_id,
        rev_id,
    })
    .await;

    let (base_rev_id, rev_id) = test.next_rev_id_pair();
    test.run_script(AddInvalidLocalRevision {
        bytes: InvalidRevisionObject::new(),
        base_rev_id,
        rev_id,
    })
    .await;

    let test = RevisionTest::new_with_other(test).await;
    test.run_scripts(vec![AssertNextSyncRevisionContent {
        expected: "123".to_string(),
    }])
    .await;
}
