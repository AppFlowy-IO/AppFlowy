use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::{AttributeEntry, AttributeValue, Changeset, NodeData};

#[test]
fn operation_update_attribute_with_float_value_test() {
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
            changeset: Changeset::Attributes {
                new: AttributeEntry::new("value", 12.2).into(),
                old: Default::default(),
            },
        },
        AssertNodeAttributes {
            path: 0.into(),
            expected: r#"{"value":12.2}"#,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_update_attribute_with_negative_value_test() {
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
            changeset: Changeset::Attributes {
                new: AttributeEntry::new("value", -12.2).into(),
                old: Default::default(),
            },
        },
        AssertNodeAttributes {
            path: 0.into(),
            expected: r#"{"value":-12.2}"#,
        },
        UpdateBody {
            path: 0.into(),
            changeset: Changeset::Attributes {
                new: AttributeEntry::new("value", AttributeValue::from_int(-12)).into(),
                old: Default::default(),
            },
        },
        AssertNodeAttributes {
            path: 0.into(),
            expected: r#"{"value":-12}"#,
        },
    ];
    test.run_scripts(scripts);
}
