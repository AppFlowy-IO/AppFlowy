use flowy_document_infra::core::{Document, PlainDoc};
use lib_ot::core::*;

#[test]
fn operation_insert_serialize_test() {
    let attributes = AttributeBuilder::new()
        .add(Attribute::Bold(true))
        .add(Attribute::Italic(true))
        .build();
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
fn attributes_serialize_test() {
    let attributes = AttributeBuilder::new()
        .add(Attribute::Bold(true))
        .add(Attribute::Italic(true))
        .build();
    let retain = OpBuilder::insert("123").attributes(attributes).build();

    let json = serde_json::to_string(&retain).unwrap();
    eprintln!("{}", json);
}

#[test]
fn delta_serialize_multi_attribute_test() {
    let mut delta = Delta::default();

    let attributes = AttributeBuilder::new()
        .add(Attribute::Bold(true))
        .add(Attribute::Italic(true))
        .build();
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
fn delta_deserialize_test() {
    let json = r#"[
        {"retain":2,"attributes":{"italic":true}},
        {"retain":2,"attributes":{"italic":123}},
        {"retain":2,"attributes":{"italic":"true","bold":"true"}},
        {"retain":2,"attributes":{"italic":true,"bold":true}}
     ]"#;
    let delta = Delta::from_json(json).unwrap();
    eprintln!("{}", delta);
}

#[test]
fn delta_deserialize_null_test() {
    let json = r#"[
        {"retain":7,"attributes":{"bold":null}}
     ]"#;
    let delta1 = Delta::from_json(json).unwrap();

    let mut attribute = Attribute::Bold(true);
    attribute.value = AttributeValue(None);
    let delta2 = DeltaBuilder::new().retain_with_attributes(7, attribute.into()).build();

    assert_eq!(delta2.to_json(), r#"[{"retain":7,"attributes":{"bold":""}}]"#);
    assert_eq!(delta1, delta2);
}

#[test]
fn delta_serde_null_test() {
    let mut attribute = Attribute::Bold(true);
    attribute.value = AttributeValue(None);
    assert_eq!(attribute.to_json(), r#"{"bold":""}"#);
}

#[test]
fn document_insert_serde_test() {
    let mut document = Document::new::<PlainDoc>();
    document.insert(0, "\n").unwrap();
    document.insert(0, "123").unwrap();
    let json = document.to_json();
    assert_eq!(r#"[{"insert":"123\n"}]"#, json);
    assert_eq!(r#"[{"insert":"123\n"}]"#, Document::from_json(&json).unwrap().to_json());
}
