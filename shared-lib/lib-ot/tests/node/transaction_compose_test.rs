use crate::node::script::{edit_node_delta, make_node_delta_changeset};
use lib_ot::core::{
    AttributeEntry, AttributeHashMap, Changeset, NodeData, NodeDataBuilder, NodeOperation, Transaction,
    TransactionBuilder,
};
use lib_ot::text_delta::DeltaTextOperationBuilder;

#[test]
fn transaction_compose_update_after_insert_test() {
    let (initial_delta, changeset, _) = make_node_delta_changeset("Hello", " world");
    let node_data = NodeDataBuilder::new("text").insert_delta(initial_delta).build();

    // Modify the same path, the operations will be merged after composing if possible.
    let mut transaction_a = TransactionBuilder::new().insert_node_at_path(0, node_data).build();
    let transaction_b = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let _ = transaction_a.compose(transaction_b).unwrap();

    // The operations are merged into one operation
    assert_eq!(transaction_a.operations.len(), 1);
    assert_eq!(
        transaction_a.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello world"}]}}]}]}"#
    );
}

#[test]
fn transaction_compose_multiple_update_test() {
    let (initial_delta, changeset_1, final_delta) = make_node_delta_changeset("Hello", " world");
    let mut transaction = TransactionBuilder::new()
        .insert_node_at_path(0, NodeDataBuilder::new("text").insert_delta(initial_delta).build())
        .build();
    let (changeset_2, _) = edit_node_delta(
        &final_delta,
        DeltaTextOperationBuilder::new()
            .retain(final_delta.utf16_target_len)
            .insert("😁")
            .build(),
    );

    let mut other_transaction = Transaction::new();

    // the following two update operations will be merged into one
    let update_1 = TransactionBuilder::new().update_node_at_path(0, changeset_1).build();
    other_transaction.compose(update_1).unwrap();

    let update_2 = TransactionBuilder::new().update_node_at_path(0, changeset_2).build();
    other_transaction.compose(update_2).unwrap();

    let inverted = Transaction::from_operations(other_transaction.operations.inverted());

    // the update operation will be merged into insert operation
    let _ = transaction.compose(other_transaction).unwrap();
    assert_eq!(transaction.operations.len(), 1);
    assert_eq!(
        transaction.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello world😁"}]}}]}]}"#
    );

    let _ = transaction.compose(inverted).unwrap();
    assert_eq!(
        transaction.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello"}]}}]}]}"#
    );
}

#[test]
fn transaction_compose_multiple_attribute_test() {
    let delta = DeltaTextOperationBuilder::new().insert("Hello").build();
    let node = NodeDataBuilder::new("text").insert_delta(delta.clone()).build();

    let insert_operation = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![node],
    };

    let mut transaction = Transaction::new();
    transaction.push_operation(insert_operation);

    let new_attribute = AttributeEntry::new("subtype", "bulleted-list");
    let update_operation = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: new_attribute.clone().into(),
            old: Default::default(),
        },
    };
    transaction.push_operation(update_operation);
    assert_eq!(
        transaction.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello"}]}}]},{"op":"update","path":[0],"changeset":{"attributes":{"new":{"subtype":"bulleted-list"},"old":{}}}}]}"#
    );

    let old_attribute = new_attribute;
    let new_attribute = AttributeEntry::new("subtype", "number-list");
    transaction.push_operation(NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: new_attribute.into(),
            old: old_attribute.into(),
        },
    });

    assert_eq!(
        transaction.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello"}]}}]},{"op":"update","path":[0],"changeset":{"attributes":{"new":{"subtype":"number-list"},"old":{"subtype":"bulleted-list"}}}}]}"#
    );
}
