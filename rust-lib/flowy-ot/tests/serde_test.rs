use flowy_ot::core::*;

#[test]
fn operation_insert_serialize_test() {
    let attributes = AttrsBuilder::new().bold(true).italic(true).build();
    let operation = Builder::insert("123").attributes(attributes).build();
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

    let attributes = AttrsBuilder::new().bold(true).italic(true).build();
    let retain = Builder::insert("123").attributes(attributes).build();

    delta.add(retain);
    delta.add(Operation::Retain(5.into()));
    delta.add(Operation::Delete(3));

    let json = serde_json::to_string(&delta).unwrap();
    eprintln!("{}", json);

    let delta_from_json: Delta = serde_json::from_str(&json).unwrap();
    assert_eq!(delta_from_json, delta);
}
