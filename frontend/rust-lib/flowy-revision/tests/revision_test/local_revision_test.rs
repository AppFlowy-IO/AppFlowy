use crate::revision_test::script::{RevisionScript::*, RevisionTest};

#[tokio::test]
async fn revision_sync_test() {
  let test = RevisionTest::new().await;
  let rev_id = 1;
  test
    .run_script(AddLocalRevision {
      content: "123".to_string(),
    })
    .await;

  test
    .run_script(AssertNextSyncRevisionId {
      rev_id: Some(rev_id),
    })
    .await;
  test.run_script(AckRevision { rev_id }).await;
  test
    .run_script(AssertNextSyncRevisionId { rev_id: None })
    .await;
}

#[tokio::test]
async fn revision_compress_2_revisions_with_2_threshold_test() {
  let test = RevisionTest::new_with_configuration(2).await;
  test
    .run_script(AddLocalRevision2 {
      content: "123".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision2 {
      content: "456".to_string(),
    })
    .await;

  test
    .run_scripts(vec![
      AssertNextSyncRevisionId { rev_id: Some(2) },
      AssertNextSyncRevisionContent {
        expected: "123456".to_string(),
      },
      AckRevision { rev_id: 2 },
      AssertNextSyncRevisionId { rev_id: None },
    ])
    .await;
}

#[tokio::test]
async fn revision_compress_4_revisions_with_threshold_2_test() {
  let test = RevisionTest::new_with_configuration(2).await;
  test
    .run_script(AddLocalRevision {
      content: "1".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "2".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "3".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "4".to_string(),
    })
    .await;

  test
    .run_scripts(vec![
      AssertNumberOfSyncRevisions { num: 2 },
      AssertNextSyncRevisionId { rev_id: Some(2) },
      AssertNextSyncRevisionContent {
        expected: "12".to_string(),
      },
      AckRevision { rev_id: 2 },
      AssertNextSyncRevisionId { rev_id: Some(4) },
      AssertNextSyncRevisionContent {
        expected: "34".to_string(),
      },
    ])
    .await;
}

#[tokio::test]
async fn revision_compress_8_revisions_with_threshold_4_test() {
  let merge_len = 4;
  let test = RevisionTest::new_with_configuration(merge_len).await;
  test
    .run_script(AddLocalRevision {
      content: "1".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "2".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "3".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "4".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "a".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "b".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "c".to_string(),
    })
    .await;

  test
    .run_script(AddLocalRevision {
      content: "d".to_string(),
    })
    .await;

  test
    .run_scripts(vec![
      AssertNumberOfSyncRevisions { num: 2 },
      AssertNextSyncRevisionId {
        rev_id: Some(merge_len),
      },
      AssertNextSyncRevisionContent {
        expected: "1234".to_string(),
      },
      AckRevision { rev_id: merge_len },
      AssertNextSyncRevisionId {
        rev_id: Some(merge_len * 2),
      },
      AssertNextSyncRevisionContent {
        expected: "abcd".to_string(),
      },
      AckRevision {
        rev_id: merge_len * 2,
      },
      AssertNextSyncRevisionId { rev_id: None },
    ])
    .await;
}

#[tokio::test]
async fn revision_merge_per_5_revision_test() {
  let merge_len = 5;
  let test = RevisionTest::new_with_configuration(merge_len).await;
  for i in 0..20 {
    let content = format!("{}", i);
    test.run_script(AddLocalRevision { content }).await;
  }

  test
    .run_scripts(vec![
      AssertNumberOfSyncRevisions { num: 4 },
      AssertNextSyncRevisionContent {
        expected: "01234".to_string(),
      },
      AckRevision { rev_id: merge_len },
      AssertNextSyncRevisionContent {
        expected: "56789".to_string(),
      },
      AckRevision {
        rev_id: merge_len * 2,
      },
      AssertNextSyncRevisionContent {
        expected: "1011121314".to_string(),
      },
      AckRevision {
        rev_id: merge_len * 3,
      },
      AssertNextSyncRevisionContent {
        expected: "1516171819".to_string(),
      },
      AckRevision {
        rev_id: merge_len * 4,
      },
      AssertNextSyncRevisionId { rev_id: None },
    ])
    .await;
}

#[tokio::test]
async fn revision_merge_per_100_revision_test() {
  let test = RevisionTest::new_with_configuration(100).await;
  for i in 0..1000 {
    let content = format!("{}", i);
    test.run_script(AddLocalRevision { content }).await;
  }

  test
    .run_scripts(vec![AssertNumberOfSyncRevisions { num: 10 }])
    .await;
}

#[tokio::test]
async fn revision_merge_per_100_revision_test2() {
  let test = RevisionTest::new_with_configuration(100).await;
  for i in 0..50 {
    test
      .run_script(AddLocalRevision {
        content: format!("{}", i),
      })
      .await;
  }

  test
    .run_scripts(vec![AssertNumberOfSyncRevisions { num: 50 }])
    .await;
}

#[tokio::test]
async fn revision_merge_per_1000_revision_test() {
  let test = RevisionTest::new_with_configuration(1000).await;
  for i in 0..100000 {
    test
      .run_script(AddLocalRevision {
        content: format!("{}", i),
      })
      .await;
  }

  test
    .run_scripts(vec![AssertNumberOfSyncRevisions { num: 100 }])
    .await;
}

#[tokio::test]
async fn revision_compress_revision_test() {
  let test = RevisionTest::new_with_configuration(2).await;
  test
    .run_scripts(vec![
      AddLocalRevision2 {
        content: "1".to_string(),
      },
      AddLocalRevision2 {
        content: "2".to_string(),
      },
      AddLocalRevision2 {
        content: "3".to_string(),
      },
      AddLocalRevision2 {
        content: "4".to_string(),
      },
      AssertNumberOfSyncRevisions { num: 2 },
    ])
    .await;
}

#[tokio::test]
async fn revision_compress_revision_while_recv_ack_test() {
  let test = RevisionTest::new_with_configuration(2).await;
  test
    .run_scripts(vec![
      AddLocalRevision2 {
        content: "1".to_string(),
      },
      AckRevision { rev_id: 1 },
      AddLocalRevision2 {
        content: "2".to_string(),
      },
      AckRevision { rev_id: 2 },
      AddLocalRevision2 {
        content: "3".to_string(),
      },
      AckRevision { rev_id: 3 },
      AddLocalRevision2 {
        content: "4".to_string(),
      },
      AssertNumberOfSyncRevisions { num: 4 },
    ])
    .await;
}
