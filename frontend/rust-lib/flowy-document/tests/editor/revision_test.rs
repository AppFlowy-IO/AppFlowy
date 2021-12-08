use flowy_test::editor::*;

#[tokio::test]
async fn create_doc() {
    let test = EditorTest::new().await;
    let editor = test.create_doc().await;
    let rev_manager = editor.rev_manager();
    assert_eq!(rev_manager.rev_id(), 0);

    let json = editor.doc_json().await.unwrap();
    assert_eq!(json, r#"[{"insert":"\n"}]"#);

    editor.insert(0, "123").await.unwrap();
    assert_eq!(rev_manager.rev_id(), 1);

    editor.insert(0, "456").await.unwrap();
    assert_eq!(rev_manager.rev_id(), 2);
}
