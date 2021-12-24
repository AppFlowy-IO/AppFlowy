// use flowy_test::doc_script::{EditorScript::*, *};
// use lib_ot::revision::RevState;
//
// #[tokio::test]
// async fn doc_sync_test() {
//     let scripts = vec![
//         InsertText("1", 0),
//         InsertText("2", 1),
//         InsertText("3", 2),
//         AssertJson(r#"[{"insert":"123\n"}]"#),
//         AssertNextRevId(None),
//     ];
//     EditorTest::new().await.run_scripts(scripts).await;
// }
//
// #[tokio::test]
// async fn doc_sync_retry_ws_conn() {
//     let scripts = vec![
//         InsertText("1", 0),
//         StopWs,
//         InsertText("2", 1),
//         InsertText("3", 2),
//         StartWs,
//         WaitSyncFinished,
//         AssertRevisionState(2, RevState::Acked),
//         AssertRevisionState(3, RevState::Acked),
//         AssertNextRevId(None),
//         AssertJson(r#"[{"insert":"123\n"}]"#),
//     ];
//     EditorTest::new().await.run_scripts(scripts).await;
// }
