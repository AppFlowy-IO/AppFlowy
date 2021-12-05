use crate::document::helper::{DocScript, DocumentTest};
use flowy_document_infra::core::{Document, FlowyDoc};
use lib_ot::core::{Attribute, Interval};

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
async fn delta_sync_while_editing() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ClientConnectWs,
        DocScript::ClientOpenDoc,
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientInsertText(3, "123"),
        DocScript::AssertClient(r#"[{"insert":"abc123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123\n"}]"#, 2),
    ])
    .await;
}

#[actix_rt::test]
async fn delta_sync_multi_revs() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ClientConnectWs,
        DocScript::ClientOpenDoc,
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientInsertText(3, "123"),
        DocScript::ClientInsertText(6, "efg"),
        DocScript::ClientInsertText(9, "456"),
    ])
    .await;
}

#[actix_rt::test]
async fn delta_sync_while_editing_with_attribute() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ClientConnectWs,
        DocScript::ClientOpenDoc,
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientFormatText(Interval::new(0, 3), Attribute::Bold(true)),
        DocScript::AssertClient(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"\n"}]"#, 2),
        DocScript::ClientInsertText(3, "efg"),
        DocScript::ClientFormatText(Interval::new(3, 5), Attribute::Italic(true)),
        DocScript::AssertClient(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"ef","attributes":{"bold":true,"italic":true}},{"insert":"g","attributes":{"bold":true}},{"insert":"\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"ef","attributes":{"bold":true,"italic":true}},{"insert":"g","attributes":{"bold":true}},{"insert":"\n"}]"#, 4),
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
        DocScript::ServerSaveDocument(json, 3),
        DocScript::ClientOpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123456\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123456\n"}]"#, 3),
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
        DocScript::ClientOpenDoc,
        DocScript::ServerSaveDocument(json, 3),
        DocScript::ClientConnectWs,
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
        DocScript::ClientOpenDoc,
        DocScript::ServerSaveDocument(json, 3),
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientConnectWs,
        DocScript::AssertClient(r#"[{"insert":"abc\n123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc\n123\n"}]"#, 4),
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
//                                     ◀─────────────────┤   call notify_open_doc with rev: 3
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
        DocScript::ServerSaveDocument(json, 1),
        DocScript::ClientOpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123\n"}]"#),
        DocScript::ClientInsertText(3, "abc"),
        DocScript::ClientInsertText(6, "efg"),
        DocScript::ClientConnectWs,
        DocScript::AssertClient(r#"[{"insert":"123abcefg\n"}]"#),
        // DocScript::AssertServer(r#"[{"insert":"123abcefg\n"}]"#, 3),
    ])
    .await;
}
