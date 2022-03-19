use crate::document::script::{EditorScript::*, *};
use flowy_revision::disk::RevisionState;
use lib_ot::core::{count_utf16_code_units, Interval};

#[tokio::test]
async fn text_block_sync_current_rev_id_check() {
    let scripts = vec![
        InsertText("1", 0),
        AssertCurrentRevId(1),
        InsertText("2", 1),
        AssertCurrentRevId(2),
        InsertText("3", 2),
        AssertCurrentRevId(3),
        AssertNextSyncRevId(None),
        AssertJson(r#"[{"insert":"123\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_state_check() {
    let scripts = vec![
        InsertText("1", 0),
        InsertText("2", 1),
        InsertText("3", 2),
        AssertRevisionState(1, RevisionState::Ack),
        AssertRevisionState(2, RevisionState::Ack),
        AssertRevisionState(3, RevisionState::Ack),
        AssertJson(r#"[{"insert":"123\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_insert_test() {
    let scripts = vec![
        InsertText("1", 0),
        InsertText("2", 1),
        InsertText("3", 2),
        AssertJson(r#"[{"insert":"123\n"}]"#),
        AssertNextSyncRevId(None),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_insert_in_chinese() {
    let s = "好".to_owned();
    let offset = count_utf16_code_units(&s);
    let scripts = vec![
        InsertText("你", 0),
        InsertText("好", offset),
        AssertJson(r#"[{"insert":"你好\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_insert_with_emoji() {
    let s = "😁".to_owned();
    let offset = count_utf16_code_units(&s);
    let scripts = vec![
        InsertText("😁", 0),
        InsertText("☺️", offset),
        AssertJson(r#"[{"insert":"😁☺️\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_delete_in_english() {
    let scripts = vec![
        InsertText("1", 0),
        InsertText("2", 1),
        InsertText("3", 2),
        Delete(Interval::new(0, 2)),
        AssertJson(r#"[{"insert":"3\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_delete_in_chinese() {
    let s = "好".to_owned();
    let offset = count_utf16_code_units(&s);
    let scripts = vec![
        InsertText("你", 0),
        InsertText("好", offset),
        Delete(Interval::new(0, offset)),
        AssertJson(r#"[{"insert":"好\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_block_sync_replace_test() {
    let scripts = vec![
        InsertText("1", 0),
        InsertText("2", 1),
        InsertText("3", 2),
        Replace(Interval::new(0, 3), "abc"),
        AssertJson(r#"[{"insert":"abc\n"}]"#),
    ];
    TextBlockEditorTest::new().await.run_scripts(scripts).await;
}
