use crate::node::script::NodeScript::{AssertNodeDelta, InsertNode, UpdateBody};
use crate::node::script::{edit_node_delta, NodeTest};
use lib_ot::core::NodeDataBuilder;
use lib_ot::text_delta::DeltaTextOperationBuilder;

#[test]
fn operation_update_delta_test() {
    let mut test = NodeTest::new();
    let initial_delta = DeltaTextOperationBuilder::new().build();
    let new_delta = DeltaTextOperationBuilder::new()
        .retain(initial_delta.utf16_base_len)
        .insert("Hello, world")
        .build();
    let (changeset, expected) = edit_node_delta(&initial_delta, new_delta);
    let node = NodeDataBuilder::new("text").insert_delta(initial_delta.clone()).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node,
            rev_id: 1,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.clone(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.inverted(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected: initial_delta,
        },
    ];
    test.run_scripts(scripts);
}
