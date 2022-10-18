use super::NodeOperations;
use crate::core::{Changeset, Node, NodeData, NodeDataBuilder, NodeOperation, Path, Transaction};
use crate::errors::{ErrorBuilder, OTError, OTErrorCode};
use indextree::{Arena, Children, FollowingSiblings, NodeId};
use std::rc::Rc;

#[derive(Debug)]
pub struct NodeTree {
    arena: Arena<Node>,
    root: NodeId,
}

impl Default for NodeTree {
    fn default() -> Self {
        Self::new("root")
    }
}

impl NodeTree {
    pub fn new(root_name: &str) -> NodeTree {
        let mut arena = Arena::new();
        let root = arena.new_node(Node::new(root_name));
        NodeTree { arena, root }
    }

    pub fn from_bytes(root_name: &str, bytes: Vec<u8>) -> Result<Self, OTError> {
        let operations = NodeOperations::from_bytes(bytes)?;
        Self::from_operations(root_name, operations)
    }

    pub fn from_operations(root_name: &str, operations: NodeOperations) -> Result<Self, OTError> {
        let mut node_tree = NodeTree::new(root_name);
        for operation in operations.into_inner().into_iter() {
            let _ = node_tree.apply_op(operation)?;
        }
        Ok(node_tree)
    }

    pub fn get_node(&self, node_id: NodeId) -> Option<&Node> {
        Some(self.arena.get(node_id)?.get())
    }

    pub fn get_node_at_path(&self, path: &Path) -> Option<&Node> {
        {
            let node_id = self.node_id_at_path(path)?;
            self.get_node(node_id)
        }
    }

    pub fn get_node_data(&self, node_id: NodeId) -> Option<NodeData> {
        let Node {
            node_type,
            body,
            attributes,
        } = self.get_node(node_id)?.clone();
        let mut node_data = NodeData::new(node_type);
        for (key, value) in attributes.into_inner() {
            node_data.attributes.insert(key, value);
        }
        node_data.body = body;

        let children = self.children_from_node(node_id);
        for child in children.into_iter() {
            if let Some(child_node_data) = self.get_node_data(child) {
                node_data.children.push(child_node_data);
            }
        }
        Some(node_data)
    }

    pub fn root_node(&self) -> NodeId {
        self.root
    }

    pub fn to_json(&self, node_id: NodeId, pretty_json: bool) -> Result<String, OTError> {
        let node_data = self
            .get_node_data(node_id)
            .ok_or(OTError::internal().context("Node doesn't exist exist"))?;
        let json = if pretty_json {
            serde_json::to_string_pretty(&node_data).map_err(|err| OTError::serde().context(err))?
        } else {
            serde_json::to_string(&node_data).map_err(|err| OTError::serde().context(err))?
        };
        Ok(json)
    }

    ///
    /// # Examples
    ///
    /// ```
    /// use std::rc::Rc;
    /// use lib_ot::core::{NodeOperation, NodeTree, NodeData, Path};
    /// let nodes = vec![NodeData::new("text".to_string())];
    /// let root_path: Path = vec![0].into();
    /// let op = NodeOperation::Insert {path: root_path.clone(),nodes };
    ///
    /// let mut node_tree = NodeTree::new("root");
    /// node_tree.apply_op(Rc::new(op)).unwrap();
    /// let node_id = node_tree.node_id_at_path(&root_path).unwrap();
    /// let node_path = node_tree.path_from_node_id(node_id);
    /// debug_assert_eq!(node_path, root_path);
    /// ```
    pub fn node_id_at_path<T: Into<Path>>(&self, path: T) -> Option<NodeId> {
        let path = path.into();
        if path.is_empty() {
            return Some(self.root);
        }

        let mut iterate_node = self.root;
        for id in path.iter() {
            iterate_node = self.child_from_node_at_index(iterate_node, *id)?;
        }
        Some(iterate_node)
    }

    pub fn path_from_node_id(&self, node_id: NodeId) -> Path {
        let mut path = vec![];
        let mut current_node = node_id;
        // Use .skip(1) on the ancestors iterator to skip the root node.
        let ancestors = node_id.ancestors(&self.arena).skip(1);
        for parent_node in ancestors {
            let counter = self.index_of_node(parent_node, current_node);
            path.push(counter);
            current_node = parent_node;
        }

        Path(path)
    }

    fn index_of_node(&self, parent_node: NodeId, child_node: NodeId) -> usize {
        let mut counter: usize = 0;
        let iter = parent_node.children(&self.arena);
        for node in iter {
            if node == child_node {
                return counter;
            }
            counter += 1;
        }

        counter
    }

    /// Returns the note_id at the position of the tree with id note_id
    /// # Arguments
    ///
    /// * `node_id`: the node id of the child's parent
    /// * `index`: index of the node in parent children list
    ///
    /// returns: Option<NodeId>
    ///
    /// # Examples
    ///
    /// ```
    /// use std::rc::Rc;
    /// use lib_ot::core::{NodeOperation, NodeTree, NodeData, Path};
    /// let node_1 = NodeData::new("text".to_string());
    /// let inserted_path: Path = vec![0].into();
    ///
    /// let mut node_tree = NodeTree::new("root");
    /// let op = NodeOperation::Insert {path: inserted_path.clone(),nodes: vec![node_1.clone()] };
    /// node_tree.apply_op(Rc::new(op)).unwrap();
    ///
    /// let node_2 = node_tree.get_node_at_path(&inserted_path).unwrap();
    /// assert_eq!(node_2.node_type, node_1.node_type);
    /// ```
    pub fn child_from_node_at_index(&self, node_id: NodeId, index: usize) -> Option<NodeId> {
        let children = node_id.children(&self.arena);
        for (counter, child) in children.enumerate() {
            if counter == index {
                return Some(child);
            }
        }

        None
    }

    /// Returns all children whose parent node id is node_id
    ///
    /// * `node_id`: the children's parent node id
    ///
    pub fn children_from_node(&self, node_id: NodeId) -> Children<'_, Node> {
        node_id.children(&self.arena)
    }

    ///
    /// # Arguments
    ///
    /// * `node_id`: if the node_is is None, then will use root node_id.
    ///
    /// returns number of the children of the root node
    ///
    pub fn number_of_children(&self, node_id: Option<NodeId>) -> usize {
        match node_id {
            None => self.root.children(&self.arena).count(),
            Some(node_id) => node_id.children(&self.arena).count(),
        }
    }

    pub fn following_siblings(&self, node_id: NodeId) -> FollowingSiblings<'_, Node> {
        node_id.following_siblings(&self.arena)
    }

    pub fn apply_transaction(&mut self, transaction: Transaction) -> Result<(), OTError> {
        let operations = transaction.into_operations();
        for operation in operations {
            self.apply_op(operation)?;
        }
        Ok(())
    }

    pub fn apply_op(&mut self, op: Rc<NodeOperation>) -> Result<(), OTError> {
        let op = match Rc::try_unwrap(op) {
            Ok(op) => op,
            Err(op) => op.as_ref().clone(),
        };

        match op {
            NodeOperation::Insert { path, nodes } => self.insert_nodes(&path, nodes),
            NodeOperation::Update { path, changeset } => self.update(&path, changeset),
            NodeOperation::Delete { path, nodes } => self.delete_node(&path, nodes),
        }
    }
    /// Inserts nodes at given path
    ///
    /// returns error if the path is empty
    ///
    fn insert_nodes(&mut self, path: &Path, nodes: Vec<NodeData>) -> Result<(), OTError> {
        debug_assert!(!path.is_empty());
        if path.is_empty() {
            return Err(OTErrorCode::PathIsEmpty.into());
        }

        let (parent_path, last_path) = path.split_at(path.0.len() - 1);
        let last_index = *last_path.first().unwrap();
        let parent_node = self
            .node_id_at_path(parent_path)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        self.insert_nodes_at_index(parent_node, last_index, nodes)
    }

    /// Inserts nodes before the node with node_id
    ///
    fn insert_nodes_before(&mut self, node_id: &NodeId, nodes: Vec<NodeData>) {
        for node in nodes {
            let (node, children) = node.split();
            let new_node_id = self.arena.new_node(node);
            if node_id.is_removed(&self.arena) {
                tracing::warn!("Node:{:?} is remove before insert", node_id);
                return;
            }

            node_id.insert_before(new_node_id, &mut self.arena);
            self.append_nodes(&new_node_id, children);
        }
    }

    fn insert_nodes_at_index(&mut self, parent: NodeId, index: usize, nodes: Vec<NodeData>) -> Result<(), OTError> {
        if index == 0 && parent.children(&self.arena).next().is_none() {
            self.append_nodes(&parent, nodes);
            return Ok(());
        }

        // Append the node to the end of the children list if index greater or equal to the
        // length of the children.
        if index >= parent.children(&self.arena).count() {
            self.append_nodes(&parent, nodes);
            return Ok(());
        }

        let node_to_insert = self
            .child_from_node_at_index(parent, index)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        self.insert_nodes_before(&node_to_insert, nodes);
        Ok(())
    }

    fn append_nodes(&mut self, parent: &NodeId, nodes: Vec<NodeData>) {
        for node in nodes {
            let (node, children) = node.split();
            let new_node_id = self.arena.new_node(node);
            parent.append(new_node_id, &mut self.arena);

            self.append_nodes(&new_node_id, children);
        }
    }

    fn delete_node(&mut self, path: &Path, nodes: Vec<NodeData>) -> Result<(), OTError> {
        let mut update_node = self
            .node_id_at_path(path)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        for _ in 0..nodes.len() {
            let next = update_node.following_siblings(&self.arena).next();
            update_node.remove_subtree(&mut self.arena);
            if let Some(next_id) = next {
                update_node = next_id;
            } else {
                break;
            }
        }
        Ok(())
    }

    fn update(&mut self, path: &Path, changeset: Changeset) -> Result<(), OTError> {
        self.mut_node_at_path(path, |node| {
            let _ = node.apply_changeset(changeset)?;
            Ok(())
        })
    }

    fn mut_node_at_path<F>(&mut self, path: &Path, f: F) -> Result<(), OTError>
    where
        F: FnOnce(&mut Node) -> Result<(), OTError>,
    {
        let node_id = self
            .node_id_at_path(path)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        match self.arena.get_mut(node_id) {
            None => tracing::warn!("The path: {:?} does not contain any nodes", path),
            Some(node) => {
                let node = node.get_mut();
                let _ = f(node)?;
            }
        }
        Ok(())
    }
}
