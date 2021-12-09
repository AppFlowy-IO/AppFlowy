use flowy_test::editor::{EditorScript::*, *};

#[tokio::test]
async fn create_doc() {
    let scripts = vec![
        InsertText("123", 0),
        AssertRevId(1),
        InsertText("456", 3),
        AssertRevId(2),
        AssertJson(r#"[{"insert":"123456\n"}]"#),
    ];
    EditorTest::new().await.run_scripts(scripts).await;
}
