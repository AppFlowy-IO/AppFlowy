use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::{AttributeEntry, Changeset, NodeData, OperationTransform};
use lib_ot::text_delta::DeltaTextOperationBuilder;

#[test]
fn changeset_delta_compose_delta_test() {
    // delta 1
    let delta_1 = DeltaTextOperationBuilder::new().insert("Hello world").build();
    let inverted_1 = delta_1.inverted();
    let mut changeset_1 = Changeset::Delta {
        delta: delta_1.clone(),
        inverted: inverted_1,
    };

    // delta 2
    let delta_2 = DeltaTextOperationBuilder::new()
        .retain(delta_1.utf16_target_len)
        .insert("!")
        .build();
    let inverted_2 = delta_2.inverted();
    let changeset_2 = Changeset::Delta {
        delta: delta_2,
        inverted: inverted_2,
    };

    // compose
    changeset_1.compose(&changeset_2).unwrap();

    if let Changeset::Delta { delta, inverted } = changeset_1 {
        assert_eq!(delta.content().unwrap(), "Hello world!");
        let new_delta = delta.compose(&inverted).unwrap();
        assert_eq!(new_delta.content().unwrap(), "");
    }
}

#[test]
fn operation_compose_delta_changeset_then_invert_test() {
    let delta = DeltaTextOperationBuilder::new().insert("Hello world").build();
    let inverted = delta.inverted();
    let changeset = Changeset::Delta {
        delta: delta.clone(),
        inverted: inverted.clone(),
    };

    let mut test = NodeTest::new();
    let text_node = NodeData::new("text");
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node,
            rev_id: 1,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.clone(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected: delta.clone(),
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.inverted(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected: delta.compose(&inverted).unwrap(),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_compose_multiple_delta_changeset_then_invert_test() {
    // delta 1
    let delta_1 = DeltaTextOperationBuilder::new().insert("Hello world").build();
    let inverted_1 = delta_1.inverted();
    let changeset_1 = Changeset::Delta {
        delta: delta_1.clone(),
        inverted: inverted_1,
    };

    // delta 2
    let delta_2 = DeltaTextOperationBuilder::new()
        .retain(delta_1.utf16_target_len)
        .insert("!")
        .build();
    let inverted_2 = delta_2.inverted();
    let changeset_2 = Changeset::Delta {
        delta: delta_2.clone(),
        inverted: inverted_2,
    };

    // delta 3
    let delta_3 = DeltaTextOperationBuilder::new()
        .retain(delta_2.utf16_target_len)
        .insert("AppFlowy")
        .build();
    let inverted_3 = delta_3.inverted();
    let changeset_3 = Changeset::Delta {
        delta: delta_3.clone(),
        inverted: inverted_3,
    };

    let mut test = NodeTest::new();
    let text_node = NodeData::new("text");
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node,
            rev_id: 1,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_1.clone(),
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_2.clone(),
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_3.clone(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected: delta_1.compose(&delta_2).unwrap().compose(&delta_3).unwrap(),
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_3.inverted(),
        },
        AssertNodeDeltaContent {
            path: 0.into(),
            expected: r#"Hello world!"#,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_2.inverted(),
        },
        AssertNodeDeltaContent {
            path: 0.into(),
            expected: r#"Hello world"#,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset_1.inverted(),
        },
        AssertNodeDeltaContent {
            path: 0.into(),
            expected: r#""#,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
#[should_panic]
fn changeset_delta_compose_attributes_test() {
    // delta 1
    let delta = DeltaTextOperationBuilder::new().insert("Hello world").build();
    let inverted = delta.inverted();
    let mut delta_changeset = Changeset::Delta { delta, inverted };

    // attributes
    let attribute_changeset = Changeset::Attributes {
        new: Default::default(),
        old: Default::default(),
    };

    // compose
    delta_changeset.compose(&attribute_changeset).unwrap();
}

#[test]
fn changeset_attributes_compose_attributes_test() {
    // attributes
    let mut changeset_1 = Changeset::Attributes {
        new: AttributeEntry::new("bold", true).into(),
        old: Default::default(),
    };

    let changeset_2 = Changeset::Attributes {
        new: AttributeEntry::new("Italic", true).into(),
        old: Default::default(),
    };
    // compose
    changeset_1.compose(&changeset_2).unwrap();

    if let Changeset::Attributes { new, old: _ } = changeset_1 {
        assert_eq!(new, AttributeEntry::new("Italic", true).into());
    }
}
