use crate::node::script::make_node_delta_changeset;
use lib_ot::core::{NodeDataBuilder, TransactionBuilder};
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
