use crate::revision_test::script::{RevisionScript::*, RevisionTest};
use flowy_revision::REVISION_WRITE_INTERVAL_IN_MILLIS;

#[tokio::test]
async fn revision_sync_test() {
    let test = RevisionTest::new().await;
    let (base_rev_id, rev_id) = test.next_rev_id_pair();

    test.run_script(AddLocalRevision {
        content: "123".to_string(),
        base_rev_id,
        rev_id,
    })
    .await;

    test.run_script(AssertNextSyncRevisionId { rev_id: Some(rev_id) }).await;
    test.run_script(AckRevision { rev_id }).await;
    test.run_script(AssertNextSyncRevisionId { rev_id: None }).await;
}

#[tokio::test]
async fn revision_sync_multiple_revisions() {
    let test = RevisionTest::new().await;
    let (base_rev_id, rev_id_1) = test.next_rev_id_pair();

    test.run_script(AddLocalRevision {
        content: "123".to_string(),
        base_rev_id,
        rev_id: rev_id_1,
    })
    .await;

    let (base_rev_id, rev_id_2) = test.next_rev_id_pair();
    test.run_script(AddLocalRevision {
        content: "456".to_string(),
        base_rev_id,
        rev_id: rev_id_2,
    })
    .await;

    test.run_scripts(vec![
        AssertNextSyncRevisionId { rev_id: Some(rev_id_1) },
        AckRevision { rev_id: rev_id_1 },
        AssertNextSyncRevisionId { rev_id: Some(rev_id_2) },
        AckRevision { rev_id: rev_id_2 },
        AssertNextSyncRevisionId { rev_id: None },
    ])
    .await;
}

#[tokio::test]
async fn revision_compress_two_revisions_test() {
    let test = RevisionTest::new().await;
    let (base_rev_id, rev_id_1) = test.next_rev_id_pair();

    test.run_script(AddLocalRevision {
        content: "123".to_string(),
        base_rev_id,
        rev_id: rev_id_1,
    })
    .await;

    // rev_id_2 will be merged with rev_id_3
    let (base_rev_id, rev_id_2) = test.next_rev_id_pair();
    test.run_script(AddLocalRevision {
        content: "456".to_string(),
        base_rev_id,
        rev_id: rev_id_2,
    })
    .await;

    let (base_rev_id, rev_id_3) = test.next_rev_id_pair();
    test.run_script(AddLocalRevision {
        content: "789".to_string(),
        base_rev_id,
        rev_id: rev_id_3,
    })
    .await;

    test.run_scripts(vec![
        Wait {
            milliseconds: REVISION_WRITE_INTERVAL_IN_MILLIS,
        },
        AssertNextSyncRevisionId { rev_id: Some(rev_id_1) },
        AckRevision { rev_id: rev_id_1 },
        AssertNextSyncRevisionId { rev_id: Some(rev_id_2) },
        AssertNextSyncRevisionContent {
            expected: "456789".to_string(),
        },
    ])
    .await;
}

#[tokio::test]
async fn revision_compress_multiple_revisions_test() {
    let test = RevisionTest::new().await;
    let mut expected = "".to_owned();

    for i in 0..100 {
        let content = format!("{}", i);
        if i != 0 {
            expected.push_str(&content);
        }
        let (base_rev_id, rev_id) = test.next_rev_id_pair();
        test.run_script(AddLocalRevision {
            content,
            base_rev_id,
            rev_id,
        })
        .await;
    }

    test.run_scripts(vec![
        Wait {
            milliseconds: REVISION_WRITE_INTERVAL_IN_MILLIS,
        },
        AssertNextSyncRevisionId { rev_id: Some(1) },
        AckRevision { rev_id: 1 },
        AssertNextSyncRevisionId { rev_id: Some(2) },
        AssertNextSyncRevisionContent { expected },
    ])
    .await;
}
