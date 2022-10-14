use lib_ot::core::{Node, Transaction};
use lib_ot::{
    core::attributes::AttributeHashMap,
    core::{Body, Changeset, NodeData, NodeTree, Path, TransactionBuilder},
    text_delta::TextOperations,
};
use std::collections::HashMap;

pub enum NodeScript {
    InsertNode {
        path: Path,
        node_data: NodeData,
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
    AssertNumberOfNodesAtPath {
        path: Option<Path>,
        len: usize,
    },
    AssertNodeData {
        path: Path,
        expected: Option<NodeData>,
    },
    AssertNode {
        path: Path,
        expected: Option<Node>,
    },
    AssertNodeDelta {
        path: Path,
        expected: TextOperations,
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
            node_tree: NodeTree::new("root"),
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
                let mut transaction = TransactionBuilder::new(&self.node_tree)
                    .insert_node_at_path(path, node)
                    .finalize();
                self.transform_transaction_if_need(&mut transaction, rev_id);
                self.apply_transaction(transaction);
            }
            NodeScript::UpdateAttributes { path, attributes } => {
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .update_attributes_at_path(&path, attributes)
                    .finalize();
                self.apply_transaction(transaction);
            }
            NodeScript::UpdateBody { path, changeset } => {
                //
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .update_body_at_path(&path, changeset)
                    .finalize();
                self.apply_transaction(transaction);
            }
            NodeScript::DeleteNode { path, rev_id } => {
                let mut transaction = TransactionBuilder::new(&self.node_tree)
                    .delete_node_at_path(&path)
                    .finalize();
                self.transform_transaction_if_need(&mut transaction, rev_id);
                self.apply_transaction(transaction);
            }
            NodeScript::AssertNode { path, expected } => {
                let node_id = self.node_tree.node_id_at_path(path);
                if expected.is_none() && node_id.is_none() {
                    return;
                }

                let node = self.node_tree.get_node(node_id.unwrap()).cloned();
                assert_eq!(node, expected);
            }
            NodeScript::AssertNodeData { path, expected } => {
                let node_id = self.node_tree.node_id_at_path(path);

                match node_id {
                    None => assert!(node_id.is_none()),
                    Some(node_id) => {
                        let node = self.node_tree.get_node(node_id).cloned();
                        assert_eq!(node, expected.map(|e| e.into()));
                    }
                }
            }
            NodeScript::AssertNumberOfNodesAtPath {
                path,
                len: expected_len,
            } => match path {
                None => {
                    let len = self.node_tree.number_of_children(None);
                    assert_eq!(len, expected_len)
                }
                Some(path) => {
                    let node_id = self.node_tree.node_id_at_path(path).unwrap();
                    let len = self.node_tree.number_of_children(Some(node_id));
                    assert_eq!(len, expected_len)
                }
            },
            NodeScript::AssertNodeDelta { path, expected } => {
                let node = self.node_tree.get_node_at_path(&path).unwrap();
                if let Body::Delta(delta) = node.body.clone() {
                    debug_assert_eq!(delta, expected);
                } else {
                    panic!("Node body type not match, expect Delta");
                }
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
