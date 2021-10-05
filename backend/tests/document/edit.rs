use crate::document::helper::{DocScript, DocumentTest};
use flowy_document::services::doc::{Document, FlowyDoc};

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
//           ┌────────────────┐ │                 │ ┌────────────────┐
//           │ops: [] rev: 0  │◀┼─────   ws   ────┼─┤ops: [] rev: 0  │
//           └────────────────┘ │                 │ └────────────────┘
//       ┌────────────────────┐ │                 │ ┌────────────────────┐
//       │ops: ["abc"] rev: 1 │◀┼─────   ws   ────┼─│ops: ["abc"] rev: 1 │
//       └────────────────────┘ │                 │ └────────────────────┘
// ┌──────────────────────────┐ │                 │ ┌──────────────────────┐
// │ops: ["abc", "123"] rev: 2│◀┼─────   ws   ────┼─│ops: ["123"] rev: 2   │
// └──────────────────────────┘ │                 │ └──────────────────────┘
//                              │                 │
#[actix_rt::test]
async fn delta_sync_after_ws_connection() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ConnectWs,
        DocScript::OpenDoc,
        DocScript::SendText(0, "abc"),
        DocScript::SendText(3, "123"),
        DocScript::AssertClient(r#"[{"insert":"abc123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123\n"}]"#),
    ])
    .await;
}

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
// ┌──────────────────────────┐ │                 │
// │ops: ["123", "456"] rev: 2│ │                 │
// └──────────────────────────┘ │                 │
//                              │                 │
//                              ◀── http request ─┤ Open doc
//                              │                 │
//                              │                 │  ┌──────────────────────────┐
//                              ├──http response──┼─▶│ops: ["123", "456"] rev: 2│
//                              │                 │  └──────────────────────────┘
#[actix_rt::test]
async fn delta_sync_with_http_request() {
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
async fn delta_sync_with_server_push_delta() {
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

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
//                              │                 │
//                              │                 │
//                              ◀── http request ─┤ Open doc
//                              │                 │
//                              │                 │  ┌───────────────┐
//                              ├──http response──┼─▶│ops: [] rev: 0 │
//         ┌───────────────────┐│                 │  └───────────────┘
//         │ops: ["123"] rev: 3││                 │
//         └───────────────────┘│                 │  ┌────────────────────┐
//                              │                 │  │ops: ["abc"] rev: 1 │
//                              │                 │  └────────────────────┘
//                              │                 │
//                              ◀─────────────────┤ start ws connection
//                              │                 │
//                              ◀─────────────────┤ notify with rev: 1
//        ┌───────────────────┐ │                 │
//        │ops: ["123"] rev: 3│ ├────Push Rev─────▶ transform
//        └───────────────────┘ │                 │ ┌──────────────────────────┐
//                              │                 │ │ops: ["abc", "123"] rev: 4│
//                              │                 │ └──────────────────────────┘
//                              │                 │ ┌────────────────────────────────┐
//                     compose  ◀────Push Rev─────┤ │ops: ["abc", "retain 3"] rev: 4 │
//                              │                 │ └────────────────────────────────┘
// ┌──────────────────────────┐ │
// │ops: ["abc", "123"] rev: 4│ │
// └──────────────────────────┘ │
//                              │              │
#[actix_rt::test]
async fn delta_sync_while_local_rev_less_than_server_rev() {
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

#[rustfmt::skip]
//                                ┌─────────┐       ┌─────────┐
//                                │ Server  │       │ Client  │
//                                └─────────┘       └─────────┘
//               ┌───────────────────┐ │                 │
//               │ops: ["123"] rev: 1│ │                 │
//               └───────────────────┘ │                 │
//                                     ◀── http request ─┤  Open doc
//                                     │                 │
//                                     │                 │   ┌───────────────┐
//                                     ├──http response──┼──▶│ops: [123] rev:│
//                                     │                 │   └───────────────┘
//                                     │                 │   ┌──────────────────────────────────┐
//                                     │                 │   │ops: ["123","abc", "efg"] rev: 3  │
//                                     │                 │   └──────────────────────────────────┘
//                                     ◀─────────────────┤   start ws connection
//                                     │                 │
//                                     ◀─────────────────┤   notify with rev: 3
//                                     │                 │
//                                     ├────Pull Rev─────▶
//                                     │                 │ ┌──────────────────────────────────┐
//                          compose    ◀────Push Rev─────┤ │ops: ["retain 3", "abcefg"] rev: 3│
// ┌──────────────────────────────────┐│                 │ └──────────────────────────────────┘
// │ops: ["123","abc", "efg"] rev: 3  ││                 │
// └──────────────────────────────────┘│                 │
#[actix_rt::test]
async fn delta_sync_while_local_rev_greater_than_server_rev() {
    let test = DocumentTest::new().await;
    let mut document = Document::new::<FlowyDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::SetServerDocument(json, 1),
        DocScript::OpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123\n"}]"#),
        DocScript::SendText(3, "abc"),
        DocScript::SendText(6, "efg"),
        DocScript::ConnectWs,
        DocScript::AssertClient(r#"[{"insert":"123abcefg\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123abcefg\n"}]"#),
    ])
    .await;
}
