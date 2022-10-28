use crate::node::script::{edit_node_delta, make_node_delta_changeset};
use lib_ot::core::{NodeDataBuilder, Transaction, TransactionBuilder};
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
fn transaction_compose_2_update_after_insert_test() {
    let (initial_delta, changeset, final_delta) = make_node_delta_changeset("Hello", " world");
    let mut transaction = TransactionBuilder::new()
        .insert_node_at_path(0, NodeDataBuilder::new("text").insert_delta(initial_delta).build())
        .build();

    // the following two update operations will be merged into one
    let mut update_1 = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let (changeset, _) = edit_node_delta(
        &final_delta,
        DeltaTextOperationBuilder::new()
            .retain(final_delta.utf16_target_len)
            .insert("😁")
            .build(),
    );
    let update_2 = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let _ = update_1.compose(update_2).unwrap();
    assert_eq!(update_1.operations.len(), 1);

    // the update operation will be merged into insert operation
    let _ = transaction.compose(update_1).unwrap();
    assert_eq!(transaction.operations.len(), 1);
    assert_eq!(
        transaction.to_json().unwrap(),
        r#"{"operations":[{"op":"insert","path":[0],"nodes":[{"type":"text","body":{"delta":[{"insert":"Hello world😁"}]}}]}]}"#
    );
}
#[test]
fn transaction_compose_2_update_then_invert_test() {
    let (initial_delta, changeset, final_delta) = make_node_delta_changeset("Hello", " world");
    let mut transaction = TransactionBuilder::new()
        .insert_node_at_path(0, NodeDataBuilder::new("text").insert_delta(initial_delta).build())
        .build();

    // the following two update operations will be merged into one
    let mut update_1 = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let (changeset, _) = edit_node_delta(
        &final_delta,
        DeltaTextOperationBuilder::new()
            .retain(final_delta.utf16_target_len)
            .insert("😁")
            .build(),
    );
    let update_2 = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let _ = update_1.compose(update_2).unwrap();
    let inverted = Transaction::from_operations(update_1.operations.inverted());

    // the update operation will be merged into insert operation
    let _ = transaction.compose(update_1).unwrap();
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
