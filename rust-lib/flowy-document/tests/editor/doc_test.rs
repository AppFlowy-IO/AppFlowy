use crate::helper::*;
use flowy_test::FlowyEnv;

#[test]
fn doc_create_test() {
    let sdk = FlowyEnv::setup().sdk;
    let doc = create_doc(&sdk, "flutter ❤️ rust");
    dbg!(&doc);

    let doc = read_doc_data(&sdk, &doc.id);
    assert_eq!(doc.data, "flutter ❤️ rust".to_owned());
}

#[test]
fn doc_update_test() {
    let sdk = FlowyEnv::setup().sdk;
    let doc_desc = create_doc(&sdk, "flutter ❤️ rust");
    dbg!(&doc_desc);

    let content = "😁😁😁😁😁😁😁😁😁😁".to_owned();
    save_doc(&sdk, &doc_desc, &content);

    let doc = read_doc_data(&sdk, &doc_desc.id);
    assert_eq!(doc.data, content);
}

#[test]
fn doc_update_big_data_test() {
    let sdk = FlowyEnv::setup().sdk;
    let doc_desc = create_doc(&sdk, "");
    let content = "flutter ❤️ rust".repeat(1000000);
    save_doc(&sdk, &doc_desc, &content);

    let doc = read_doc_data(&sdk, &doc_desc.id);
    assert_eq!(doc.data, content);
}
