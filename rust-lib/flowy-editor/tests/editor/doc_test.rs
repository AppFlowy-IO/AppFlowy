use crate::helper::*;

#[test]
fn file_create_test() {
    let doc_desc = create_doc("hello world", "flutter ❤️ rust");
    dbg!(&doc_desc);
}

#[test]
fn file_save_test() {
    let content = "😁😁😁😁😁😁😁😁😁😁".to_owned();
    let doc_desc = create_doc("hello world", "flutter ❤️ rust");
    dbg!(&doc_desc);
    save_doc(&doc_desc, &content);

    let doc = read_doc(&doc_desc.id);
    assert_eq!(doc.content, content);
}
