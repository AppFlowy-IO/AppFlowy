use crate::document::helper::{DocScript, DocumentTest};

#[actix_rt::test]
async fn edit_doc_insert_text() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![DocScript::SendText("abc")]).await;
}
