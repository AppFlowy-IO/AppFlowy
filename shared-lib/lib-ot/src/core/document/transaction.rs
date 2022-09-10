use crate::core::document::path::Path;
use crate::core::{Node, NodeAttributes, NodeOperation, NodeTree};
use indextree::NodeId;

pub struct Transaction {
    pub operations: Vec<NodeOperation>,
}

impl Transaction {
    fn new(operations: Vec<NodeOperation>) -> Transaction {
        Transaction { operations }
    }
}

pub struct TransactionBuilder<'a> {
    node_tree: &'a NodeTree,
    operations: Vec<NodeOperation>,
}

impl<'a> TransactionBuilder<'a> {
    pub fn new(node_tree: &'a NodeTree) -> TransactionBuilder {
        TransactionBuilder {
            node_tree,
            operations: Vec::new(),
        }
    }

    ///
    ///
    /// # Arguments
    ///
    /// * `path`: the path that is used to save the nodes
    /// * `nodes`: the nodes you will be save in the path
    ///
    /// # Examples
    ///
    /// ```
    /// // -- 0 (root)
    /// //      0 -- text_1
    /// //      1 -- text_2
    /// use lib_ot::core::{NodeTree, Node, TransactionBuilder};
    /// let mut node_tree = NodeTree::new();
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_nodes_at_path(0,vec![ Node::new("text_1"),  Node::new("text_2")])
    ///     .finalize();
    ///  node_tree.apply(transaction).unwrap();
    ///
    ///  node_tree.node_at_path(vec![0, 0]);
    /// ```
    ///
    pub fn insert_nodes_at_path<T: Into<Path>>(self, path: T, nodes: Vec<Node>) -> Self {
        self.push(NodeOperation::Insert {
            path: path.into(),
            nodes,
        })
    }

    ///
    ///
    /// # Arguments
    ///
    /// * `path`: the path that is used to save the nodes
    /// * `node`: the node data will be saved in the path
    ///
    /// # Examples
    ///
    /// ```
    /// // 0
    /// // -- 0
    /// //    |-- text
    /// use lib_ot::core::{NodeTree, Node, TransactionBuilder};
    /// let mut node_tree = NodeTree::new();
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_node_at_path(0, Node::new("text"))
    ///     .finalize();
    ///  node_tree.apply(transaction).unwrap();
    /// ```
    ///
    pub fn insert_node_at_path<T: Into<Path>>(self, path: T, node: Node) -> Self {
        self.insert_nodes_at_path(path, vec![node])
    }

    pub fn update_attributes_at_path(self, path: &Path, attributes: NodeAttributes) -> Self {
        let mut old_attributes = NodeAttributes::new();
        let node = self.node_tree.node_at_path(path).unwrap();
        let node_data = self.node_tree.get_node_data(node).unwrap();

        for key in attributes.keys() {
            let old_attrs = &node_data.attributes;
            if let Some(value) = old_attrs.get(key.as_str()) {
                old_attributes.insert(key.clone(), value.clone());
            }
        }

        self.push(NodeOperation::Update {
            path: path.clone(),
            attributes,
            old_attributes,
        })
    }

    pub fn delete_node_at_path(self, path: &Path) -> Self {
        self.delete_nodes_at_path(path, 1)
    }

    pub fn delete_nodes_at_path(mut self, path: &Path, length: usize) -> Self {
        let mut node = self.node_tree.node_at_path(path).unwrap();
        let mut deleted_nodes = vec![];
        for _ in 0..length {
            deleted_nodes.push(self.get_deleted_nodes(node));
            node = self.node_tree.following_siblings(node).next().unwrap();
        }

        self.operations.push(NodeOperation::Delete {
            path: path.clone(),
            nodes: deleted_nodes,
        });
        self
    }

    fn get_deleted_nodes(&self, node_id: NodeId) -> Node {
        let node_data = self.node_tree.get_node_data(node_id).unwrap();

        let mut children = vec![];
        self.node_tree.children_from_node(node_id).for_each(|child_id| {
            children.push(self.get_deleted_nodes(child_id));
        });

        Node {
            node_type: node_data.node_type.clone(),
            attributes: node_data.attributes.clone(),
            body: node_data.body.clone(),
            children,
        }
    }

    pub fn push(mut self, op: NodeOperation) -> Self {
        self.operations.push(op);
        self
    }

    pub fn finalize(self) -> Transaction {
        Transaction::new(self.operations)
    }
}
