use flowy_ot::{
    attributes::{Attributes, AttributesBuilder},
    delta::Delta,
    operation::{OpBuilder, Operation, Retain},
};

#[test]
fn operation_insert_serialize_test() {
    let attributes = AttributesBuilder::new().bold().italic().build();
    let operation = OpBuilder::insert("123".to_owned())
        .attributes(Some(attributes))
        .build();
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

    let attributes = AttributesBuilder::new().bold().italic().build();
    let retain = OpBuilder::insert("123".to_owned())
        .attributes(Some(attributes))
        .build();

    delta.add(retain);
    delta.add(Operation::Retain(5.into()));
    delta.add(Operation::Delete(3));

    let json = serde_json::to_string(&delta).unwrap();
    eprintln!("{}", json);

    let delta_from_json: Delta = serde_json::from_str(&json).unwrap();
    assert_eq!(delta_from_json, delta);
}
