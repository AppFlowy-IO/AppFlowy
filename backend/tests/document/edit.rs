use crate::document::helper::{DocScript, DocumentTest};

#[actix_rt::test]
async fn edit_doc_insert_text() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::SendText(0, "abc"),
        DocScript::SendText(3, "123"),
        DocScript::SendText(6, "efg"),
        DocScript::AssertClient(r#"[{"insert":"abc123efg\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123efg\n"}]"#),
    ])
    .await;
}
