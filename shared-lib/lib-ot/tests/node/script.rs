use lib_ot::core::{
    NodeAttributes, NodeBody, NodeBodyChangeset, NodeData, NodeTree, Path, TextDelta, TransactionBuilder,
};

pub enum NodeScript {
    InsertNode { path: Path, node: NodeData },
    UpdateAttributes { path: Path, attributes: NodeAttributes },
    UpdateBody { path: Path, changeset: NodeBodyChangeset },
    DeleteNode { path: Path },
    AssertNumberOfChildrenAtPath { path: Option<Path>, len: usize },
    AssertNode { path: Path, expected: Option<NodeData> },
    AssertNodeDelta { path: Path, expected: TextDelta },
}

pub struct NodeTest {
    node_tree: NodeTree,
}

impl NodeTest {
    pub fn new() -> Self {
        Self {
            node_tree: NodeTree::new(),
        }
    }

    pub fn run_scripts(&mut self, scripts: Vec<NodeScript>) {
        for script in scripts {
            self.run_script(script);
        }
    }

    pub fn run_script(&mut self, script: NodeScript) {
        match script {
            NodeScript::InsertNode { path, node } => {
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .insert_node_at_path(path, node)
                    .finalize();

                self.node_tree.apply(transaction).unwrap();
            }
            NodeScript::UpdateAttributes { path, attributes } => {
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .update_attributes_at_path(&path, attributes)
                    .finalize();
                self.node_tree.apply(transaction).unwrap();
            }
            NodeScript::UpdateBody { path, changeset } => {
                //
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .update_body_at_path(&path, changeset)
                    .finalize();
                self.node_tree.apply(transaction).unwrap();
            }
            NodeScript::DeleteNode { path } => {
                let transaction = TransactionBuilder::new(&self.node_tree)
                    .delete_node_at_path(&path)
                    .finalize();
                self.node_tree.apply(transaction).unwrap();
            }
            NodeScript::AssertNode { path, expected } => {
                let node_id = self.node_tree.node_id_at_path(path);

                match node_id {
                    None => assert!(node_id.is_none()),
                    Some(node_id) => {
                        let node_data = self.node_tree.get_node(node_id).cloned();
                        assert_eq!(node_data, expected.and_then(|e| Some(e.into())));
                    }
                }
            }
            NodeScript::AssertNumberOfChildrenAtPath {
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
                if let NodeBody::Delta(delta) = node.body.clone() {
                    debug_assert_eq!(delta, expected);
                } else {
                    panic!("Node body type not match, expect Delta");
                }
            }
        }
    }
}
