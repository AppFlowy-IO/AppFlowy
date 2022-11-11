#![allow(clippy::all)]
use lib_ot::core::{NodeTreeContext, OperationTransform, Transaction};
use lib_ot::text_delta::DeltaTextOperationBuilder;
use lib_ot::{
    core::attributes::AttributeHashMap,
    core::{Body, Changeset, NodeData, NodeTree, Path, TransactionBuilder},
    text_delta::DeltaTextOperations,
};
use std::collections::HashMap;

pub enum NodeScript {
    InsertNode {
        path: Path,
        node_data: NodeData,
        rev_id: usize,
    },
    InsertNodes {
        path: Path,
        node_data_list: Vec<NodeData>,
        rev_id: usize,
    },
    UpdateAttributes {
        path: Path,
        attributes: AttributeHashMap,
    },
    UpdateBody {
        path: Path,
        changeset: Changeset,
    },
    DeleteNode {
        path: Path,
        rev_id: usize,
    },
    AssertNumberOfChildrenAtPath {
        path: Option<Path>,
        expected: usize,
    },
    AssertNodesAtRoot {
        expected: Vec<NodeData>,
    },
    #[allow(dead_code)]
    AssertNodesAtPath {
        path: Path,
        expected: Vec<NodeData>,
    },
    AssertNode {
        path: Path,
        expected: Option<NodeData>,
    },
    AssertNodeAttributes {
        path: Path,
        expected: &'static str,
    },
    AssertNodeDelta {
        path: Path,
        expected: DeltaTextOperations,
    },
    AssertNodeDeltaContent {
        path: Path,
        expected: &'static str,
    },
    #[allow(dead_code)]
    AssertTreeJSON {
        expected: String,
    },
}

pub struct NodeTest {
    rev_id: usize,
    rev_operations: HashMap<usize, Transaction>,
    node_tree: NodeTree,
}

impl NodeTest {
    pub fn new() -> Self {
        Self {
            rev_id: 0,
            rev_operations: HashMap::new(),
            node_tree: NodeTree::new(NodeTreeContext::default()),
        }
    }

    pub fn run_scripts(&mut self, scripts: Vec<NodeScript>) {
        for script in scripts {
            self.run_script(script);
        }
    }

    pub fn run_script(&mut self, script: NodeScript) {
        match script {
            NodeScript::InsertNode {
                path,
                node_data: node,
                rev_id,
            } => {
                let mut transaction = TransactionBuilder::new().insert_node_at_path(path, node).build();
                self.transform_transaction_if_need(&mut transaction, rev_id);
                self.apply_transaction(transaction);
            }
            NodeScript::InsertNodes {
                path,
                node_data_list,
                rev_id,
            } => {
                let mut transaction = TransactionBuilder::new()
                    .insert_nodes_at_path(path, node_data_list)
                    .build();
                self.transform_transaction_if_need(&mut transaction, rev_id);
                self.apply_transaction(transaction);
            }
            NodeScript::UpdateAttributes { path, attributes } => {
                let node = self.node_tree.get_node_data_at_path(&path).unwrap();
                let transaction = TransactionBuilder::new()
                    .update_node_at_path(
                        &path,
                        Changeset::Attributes {
                            new: attributes,
                            old: node.attributes,
                        },
                    )
                    .build();
                self.apply_transaction(transaction);
            }
            NodeScript::UpdateBody { path, changeset } => {
                //
                let transaction = TransactionBuilder::new().update_node_at_path(&path, changeset).build();
                self.apply_transaction(transaction);
            }
            NodeScript::DeleteNode { path, rev_id } => {
                let mut transaction = TransactionBuilder::new()
                    .delete_node_at_path(&self.node_tree, &path)
                    .build();
                self.transform_transaction_if_need(&mut transaction, rev_id);
                self.apply_transaction(transaction);
            }

            NodeScript::AssertNode { path, expected } => {
                let node = self.node_tree.get_node_data_at_path(&path);
                assert_eq!(node, expected.map(|e| e.into()));
            }
            NodeScript::AssertNodeAttributes { path, expected } => {
                let node = self.node_tree.get_node_data_at_path(&path).unwrap();
                assert_eq!(node.attributes.to_json().unwrap(), expected);
            }
            NodeScript::AssertNumberOfChildrenAtPath { path, expected } => match path {
                None => {
                    let len = self.node_tree.number_of_children(None);
                    assert_eq!(len, expected)
                }
                Some(path) => {
                    let node_id = self.node_tree.node_id_at_path(path).unwrap();
                    let len = self.node_tree.number_of_children(Some(node_id));
                    assert_eq!(len, expected)
                }
            },
            NodeScript::AssertNodesAtRoot { expected } => {
                let nodes = self.node_tree.get_node_data_at_root().unwrap().children;
                assert_eq!(nodes, expected)
            }
            NodeScript::AssertNodesAtPath { path, expected } => {
                let nodes = self.node_tree.get_node_data_at_path(&path).unwrap().children;
                assert_eq!(nodes, expected)
            }
            NodeScript::AssertNodeDelta { path, expected } => {
                let node = self.node_tree.get_node_at_path(&path).unwrap();
                if let Body::Delta(delta) = node.body.clone() {
                    debug_assert_eq!(delta, expected);
                } else {
                    panic!("Node body type not match, expect Delta");
                }
            }
            NodeScript::AssertNodeDeltaContent { path, expected } => {
                let node = self.node_tree.get_node_at_path(&path).unwrap();
                if let Body::Delta(delta) = node.body.clone() {
                    debug_assert_eq!(delta.content().unwrap(), expected);
                } else {
                    panic!("Node body type not match, expect Delta");
                }
            }
            NodeScript::AssertTreeJSON { expected } => {
                let json = serde_json::to_string(&self.node_tree).unwrap();
                assert_eq!(json, expected)
            }
        }
    }

    fn apply_transaction(&mut self, transaction: Transaction) {
        self.rev_id += 1;
        self.rev_operations.insert(self.rev_id, transaction.clone());
        self.node_tree.apply_transaction(transaction).unwrap();
    }

    fn transform_transaction_if_need(&mut self, transaction: &mut Transaction, rev_id: usize) {
        if self.rev_id >= rev_id {
            for rev_id in rev_id..=self.rev_id {
                let old_transaction = self.rev_operations.get(&rev_id).unwrap();
                *transaction = old_transaction.transform(transaction).unwrap();
            }
        }
    }
}

pub fn edit_node_delta(
    delta: &DeltaTextOperations,
    new_delta: DeltaTextOperations,
) -> (Changeset, DeltaTextOperations) {
    let inverted = new_delta.invert(&delta);
    let expected = delta.compose(&new_delta).unwrap();
    let changeset = Changeset::Delta {
        delta: new_delta.clone(),
        inverted: inverted.clone(),
    };
    (changeset, expected)
}

pub fn make_node_delta_changeset(
    initial_content: &str,
    insert_str: &str,
) -> (DeltaTextOperations, Changeset, DeltaTextOperations) {
    let initial_content = initial_content.to_owned();
    let initial_delta = DeltaTextOperationBuilder::new().insert(&initial_content).build();
    let delta = DeltaTextOperationBuilder::new()
        .retain(initial_content.len())
        .insert(insert_str)
        .build();
    let inverted = delta.invert(&initial_delta);
    let expected = initial_delta.compose(&delta).unwrap();
    let changeset = Changeset::Delta {
        delta: delta.clone(),
        inverted: inverted.clone(),
    };
    (initial_delta, changeset, expected)
}
