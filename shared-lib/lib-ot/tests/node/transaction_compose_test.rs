use crate::node::script::make_node_delta_changeset;
use lib_ot::core::{NodeDataBuilder, TransactionBuilder};
use lib_ot::text_delta::DeltaTextOperationBuilder;

#[test]
fn transaction_compose_test() {
    let (initial_delta, changeset, _, expected_delta) = make_node_delta_changeset("Hello", " world");
    let node_data = NodeDataBuilder::new("text").insert_delta(initial_delta).build();
    let mut transaction_a = TransactionBuilder::new().insert_node_at_path(0, node_data).build();
    let transaction_b = TransactionBuilder::new().update_node_at_path(0, changeset).build();
    let _ = transaction_a.compose(transaction_b).unwrap();

    assert_eq!(transaction_a.operations.len(), 1)
}
