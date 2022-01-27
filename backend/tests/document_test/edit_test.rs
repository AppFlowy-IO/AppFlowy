use crate::document_test::edit_script::{DocScript, DocumentTest};
use flowy_collaboration::client_document::{ClientDocument, NewlineDoc};
use lib_ot::{core::Interval, rich_text::RichTextAttribute};

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
//           ┌────────────────┐ │                 │ ┌────────────────┐
//           │ops: [] rev: 0  │◀┼────  Ping  ─────┼─┤ops: [] rev: 0  │
//           └────────────────┘ │                 │ └────────────────┘
//       ┌────────────────────┐ │                 │ ┌────────────────────┐
//       │ops: ["abc"] rev: 1 │◀┼───ClientPush ───┼─│ops: ["abc"] rev: 1 │
//       └────────────────────┘ │                 │ └────────────────────┘
// ┌──────────────────────────┐ │                 │ ┌──────────────────────┐
// │ops: ["abc", "123"] rev: 2│◀┼── ClientPush ───┼─│ops: ["123"] rev: 2   │
// └──────────────────────────┘ │                 │ └──────────────────────┘
//                              │                 │
#[actix_rt::test]
async fn delta_sync_while_editing() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
        DocScript::ClientOpenDoc,
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientInsertText(3, "123"),
        DocScript::AssertClient(r#"[{"insert":"abc123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123\n"}]"#, 1),
    ])
    .await;
}

#[actix_rt::test]
async fn delta_sync_multi_revs() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![
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
        DocScript::ClientOpenDoc,
        DocScript::ClientInsertText(0, "abc"),
        DocScript::ClientFormatText(Interval::new(0, 3), RichTextAttribute::Bold(true)),
        DocScript::AssertClient(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"\n"}]"#, 1),
        DocScript::ClientInsertText(3, "efg"),
        DocScript::ClientFormatText(Interval::new(3, 5), RichTextAttribute::Italic(true)),
        DocScript::AssertClient(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"ef","attributes":{"bold":true,"italic":true}},{"insert":"g","attributes":{"bold":true}},{"insert":"\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc","attributes":{"bold":true}},{"insert":"ef","attributes":{"bold":true,"italic":true}},{"insert":"g","attributes":{"bold":true}},{"insert":"\n"}]"#, 3),
    ])
    .await;
}

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
// ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │                 │
//  ops: ["123", "456"] rev: 3│ │                 │
// └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │                 │
//                              │                 │
//                              ◀─────  Ping   ───┤ Open doc
//                              │                 │
//                              │                 │  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                              ├───ServerPush────┼─▶ ops: ["123", "456"] rev: 3│
//                              │                 │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
#[actix_rt::test]
async fn delta_sync_with_server_push() {
    let test = DocumentTest::new().await;
    let mut document = ClientDocument::new::<NewlineDoc>();
    document.insert(0, "123").unwrap();
    document.insert(3, "456").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::ServerResetDocument(json, 3),
        DocScript::ClientOpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123456\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123456\n"}]"#, 3),
    ])
    .await;
}

#[rustfmt::skip]
//                    ┌─────────┐       ┌─────────┐
//                    │ Server  │       │ Client  │
//                    └─────────┘       └─────────┘
//             ┌ ─ ─ ─ ─ ┐ │                 │
//              ops: []    │                 │
//             └ ─ ─ ─ ─ ┘ │                 │
//                         │                 │
//                         ◀─────  Ping   ───┤ Open doc
//                         ◀─────  Ping   ───┤
//                         ◀─────  Ping   ───┤
// ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │                 │
//  ops: ["123"], rev: 3   │                 │
// └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │                 │  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
//                         ├────ServerPush───▶   ops: ["123"] rev: 3
//                         │                 │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
//                         │                 │
#[actix_rt::test]
async fn delta_sync_with_server_push_after_reset_document() {
    let test = DocumentTest::new().await;
    let mut document = ClientDocument::new::<NewlineDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::ClientOpenDoc,
        DocScript::ServerResetDocument(json, 3),
        DocScript::AssertClient(r#"[{"insert":"123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123\n"}]"#, 3),
    ])
    .await;
}

#[rustfmt::skip]
//                         ┌─────────┐       ┌─────────┐
//                         │ Server  │       │ Client  │
//                         └─────────┘       └─────────┘
//                              │                 │
//                              │                 │
//                              ◀────── Ping ─────┤ Open doc
//        ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │                 │
//         ops: ["123"] rev: 3  │                 │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//        └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │                 │  ops: ["abc"] rev: 1 │
//                              │                 │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                              │                 │ ┌────────────────────┐
//                              ◀───ClientPush ───┤ │ops: ["abc"] rev: 1 │
//        ┌───────────────────┐ │                 │ └────────────────────┘
//        │ops: ["123"] rev: 3│ ├────ServerPush───▶  transform
//        └───────────────────┘ │                 │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                              │                 │  ops: ["abc", "123"] rev: 4│
//                              │                 │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                              │                 │ ┌────────────────────────────────┐
//                              ◀────ClientPush───┤ │ops: ["retain 3","abc"] rev: 4  │
// ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │                 │ └────────────────────────────────┘
//  ops: ["abc", "123"] rev: 4│ ├────ServerAck────▶
// └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │                 │
#[actix_rt::test]
async fn delta_sync_while_local_rev_less_than_server_rev() {
    let test = DocumentTest::new().await;
    let mut document = ClientDocument::new::<NewlineDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::ClientOpenDoc,
        DocScript::ServerResetDocument(json, 3),
        DocScript::ClientInsertText(0, "abc"),
        DocScript::AssertClient(r#"[{"insert":"abc123\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"abc123\n"}]"#, 4),
    ])
    .await;
}

#[rustfmt::skip]
//                                  ┌─────────┐       ┌─────────┐
//                                  │ Server  │       │ Client  │
//                                  └─────────┘       └─────────┘
//                 ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │                 │
//                  ops: ["123"] rev: 1  │                 │
//                 └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │                 │
//                                       ◀────  Ping   ────┤  Open doc
//                                       │                 │
//                                       │                 │ ┌──────────────────┐
//                                       ├───ServerPush────▶ │ops: [123] rev: 1 │
//                                       │                 │ └──────────────────┘
//                                       │                 │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                                       │                 │  ops: ["123","abc", "efg"] rev: 3  │
//                                       │                 │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
//                                       │                 │ ┌──────────────────────────────┐
//                                       ◀────ClientPush───┤ │ops: [retain 3, "abc"] rev: 2 │
//         ┌──────────────────────────┐  │                 │ └──────────────────────────────┘
//         │ops: ["123","abc"] rev: 2 │  ├────ServerAck────▶
//         └──────────────────────────┘  │                 │
//                                       │                 │ ┌──────────────────────────────┐
//                                       ◀────ClientPush───┤ │ops: [retain 6, "efg"] rev: 3 │
// ┌──────────────────────────────────┐  │                 │ └──────────────────────────────┘
// │ops: ["123","abc", "efg"] rev: 3  │  ├────ServerAck────▶
// └──────────────────────────────────┘  │                 │
#[actix_rt::test]
async fn delta_sync_while_local_rev_greater_than_server_rev() {
    let test = DocumentTest::new().await;
    let mut document = ClientDocument::new::<NewlineDoc>();
    document.insert(0, "123").unwrap();
    let json = document.to_json();

    test.run_scripts(vec![
        DocScript::ServerResetDocument(json, 1),
        DocScript::ClientOpenDoc,
        DocScript::AssertClient(r#"[{"insert":"123\n"}]"#),
        DocScript::ClientInsertText(3, "abc"),
        DocScript::ClientInsertText(6, "efg"),
        DocScript::AssertClient(r#"[{"insert":"123abcefg\n"}]"#),
        DocScript::AssertServer(r#"[{"insert":"123abcefg\n"}]"#, 3),
    ])
    .await;
}
