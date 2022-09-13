use flowy_sync::client_document::{ClientDocument, EmptyDoc};
use lib_ot::text_delta::TextOperation;
use lib_ot::{
    core::*,
    text_delta::{BuildInTextAttribute, TextDelta},
};

#[test]
fn operation_insert_serialize_test() {
    let attributes = AttributeBuilder::new()
        .insert("bold", true)
        .insert("italic", true)
        .build();
    let operation = Operation::insert_with_attributes("123", attributes);
    let json = serde_json::to_string(&operation).unwrap();
    eprintln!("{}", json);

    let insert_op: TextOperation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn operation_retain_serialize_test() {
    let operation = Operation::Retain(12.into());
    let json = serde_json::to_string(&operation).unwrap();
    eprintln!("{}", json);
    let insert_op: TextOperation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn operation_delete_serialize_test() {
    let operation = TextOperation::Delete(2);
    let json = serde_json::to_string(&operation).unwrap();
    let insert_op: TextOperation = serde_json::from_str(&json).unwrap();
    assert_eq!(insert_op, operation);
}

#[test]
fn attributes_serialize_test() {
    let attributes = AttributeBuilder::new()
        .insert_entry(BuildInTextAttribute::Bold(true))
        .insert_entry(BuildInTextAttribute::Italic(true))
        .build();
    let retain = Operation::insert_with_attributes("123", attributes);

    let json = serde_json::to_string(&retain).unwrap();
    eprintln!("{}", json);
}

#[test]
fn delta_serialize_multi_attribute_test() {
    let mut delta = Operations::default();

    let attributes = AttributeBuilder::new()
        .insert_entry(BuildInTextAttribute::Bold(true))
        .insert_entry(BuildInTextAttribute::Italic(true))
        .build();
    let retain = Operation::insert_with_attributes("123", attributes);

    delta.add(retain);
    delta.add(Operation::Retain(5.into()));
    delta.add(Operation::Delete(3));

    let json = serde_json::to_string(&delta).unwrap();
    eprintln!("{}", json);

    let delta_from_json = Operations::from_json(&json).unwrap();
    assert_eq!(delta_from_json, delta);
}

#[test]
fn delta_deserialize_test() {
    let json = r#"[
        {"retain":2,"attributes":{"italic":true}},
        {"retain":2,"attributes":{"italic":123}},
        {"retain":2,"attributes":{"italic":true,"bold":true}},
        {"retain":2,"attributes":{"italic":true,"bold":true}}
     ]"#;
    let delta = TextDelta::from_json(json).unwrap();
    eprintln!("{}", delta);
}

#[test]
fn delta_deserialize_null_test() {
    let json = r#"[
        {"retain":7,"attributes":{"bold":null}}
     ]"#;
    let delta1 = TextDelta::from_json(json).unwrap();

    let mut attribute = BuildInTextAttribute::Bold(true);
    attribute.remove_value();

    let delta2 = OperationBuilder::new()
        .retain_with_attributes(7, attribute.into())
        .build();

    assert_eq!(delta2.json_str(), r#"[{"retain":7,"attributes":{"bold":null}}]"#);
    assert_eq!(delta1, delta2);
}

#[test]
fn document_insert_serde_test() {
    let mut document = ClientDocument::new::<EmptyDoc>();
    document.insert(0, "\n").unwrap();
    document.insert(0, "123").unwrap();
    let json = document.delta_str();
    assert_eq!(r#"[{"insert":"123\n"}]"#, json);
    assert_eq!(
        r#"[{"insert":"123\n"}]"#,
        ClientDocument::from_json(&json).unwrap().delta_str()
    );
}
