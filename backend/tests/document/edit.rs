use crate::document::helper::{DocScript, DocumentTest};
use flowy_document::services::doc::{Document, FlowyDoc};
use flowy_ot::core::Delta;

#[actix_rt::test]
async fn sync_doc_insert_text() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ConnectWs,
        DocScript::OpenDoc,
        DocScript::SendText(0, "abc"),
        DocScript::SendText(3, "123"),
        DocScript::SendText(6, "efg"),
        DocScript::AssertClient(r#"[{"insert":"abc123efg\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123efg\n"}]"#),
    ])
    .await;
}

#[actix_rt::test]
async fn sync_open_empty_doc_and_sync_from_server() {
    let test = DocumentTest::new().await;
    let mut document = Document::new::<FlowyDoc>();
    document.insert(0, "123").unwrap();
    document.insert(3, "456").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::SetServerDocument(json, 3),
        DocScript::OpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123456\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123456\n"}]"#),
    ])
    .await;
}

#[actix_rt::test]
async fn sync_open_empty_doc_and_sync_from_server_using_ws() {
    let test = DocumentTest::new().await;
    let mut document = Document::new::<FlowyDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::OpenDoc,
        DocScript::SetServerDocument(json, 3),
        DocScript::ConnectWs,
        DocScript::AssertClient(r#"[{"insert":"\n123\n"}]"#),
    ])
    .await;
}

#[actix_rt::test]
async fn sync_open_non_empty_doc_and_sync_with_sever() {
    let test = DocumentTest::new().await;
    let mut document = Document::new::<FlowyDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::OpenDoc,
        DocScript::SetServerDocument(json, 3),
        DocScript::SendText(0, "abc"),
        DocScript::ConnectWs,
        DocScript::AssertClient(r#"[{"insert":"abc\n123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc\n123\n"}]"#),
    ])
    .await;
}
