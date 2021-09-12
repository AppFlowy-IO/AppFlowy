use flowy_ot::{client::Document, core::*};

#[test]
fn operation_insert_serialize_test() {
    let attributes = AttributeBuilder::new().bold(true).italic(true).build();
    let operation = OpBuilder::insert("123").attributes(attributes).build();
    let json = serde_json::to_string(&operation).unwrap();
    eprintln!("{}", json);

    let insert_op: Operation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn operation_retain_serialize_test() {
    let operation = Operation::Retain(12.into());
    let json = serde_json::to_string(&operation).unwrap();
    eprintln!("{}", json);
    let insert_op: Operation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn operation_delete_serialize_test() {
    let operation = Operation::Delete(2);
    let json = serde_json::to_string(&operation).unwrap();
    let insert_op: Operation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn delta_serialize_test() {
    let mut delta = Delta::default();

    let attributes = AttributeBuilder::new().bold(true).italic(true).build();
    let retain = OpBuilder::insert("123").attributes(attributes).build();

    delta.add(retain);
    delta.add(Operation::Retain(5.into()));
    delta.add(Operation::Delete(3));

    let json = serde_json::to_string(&delta).unwrap();
    eprintln!("{}", json);

    let delta_from_json = Delta::from_json(&json).unwrap();
    assert_eq!(delta_from_json, delta);
}

#[test]
fn document_insert_serde_test() {
    let mut document = Document::new();
    document.insert(0, "\n");
    document.insert(0, "123");
    let json = document.to_json();
    assert_eq!(r#"[{"insert":"123\n"}]"#, json);
    assert_eq!(r#"[{"insert":"123\n"}]"#, Document::from_json(&json).unwrap().to_json());
}
