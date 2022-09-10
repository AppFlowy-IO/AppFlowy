use crate::core::document::path::Path;
use crate::core::{Node, NodeAttributes, NodeBodyChangeset, NodeData, NodeOperation, OperationTransform, Transaction};
use crate::errors::{ErrorBuilder, OTError, OTErrorCode};
use indextree::{Arena, Children, FollowingSiblings, NodeId};

///
pub struct NodeTree {
    arena: Arena<NodeData>,
    root: NodeId,
}

impl Default for NodeTree {
    fn default() -> Self {
        Self::new()
    }
}

impl NodeTree {
    pub fn new() -> NodeTree {
        let mut arena = Arena::new();
        let root = arena.new_node(NodeData::new("root"));
        NodeTree { arena, root }
    }

    pub fn get_node_data(&self, node_id: NodeId) -> Option<&NodeData> {
        Some(self.arena.get(node_id)?.get())
    }

    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{NodeOperation, NodeTree, Node, Path};
    /// let nodes = vec![Node::new("text".to_string())];
    /// let root_path: Path = vec![0].into();
    /// let op = NodeOperation::Insert {path: root_path.clone(),nodes };
    ///
    /// let mut node_tree = NodeTree::new();
    /// node_tree.apply_op(&op).unwrap();
    /// let node_id = node_tree.node_at_path(&root_path).unwrap();
    /// let node_path = node_tree.path_of_node(node_id);
    /// debug_assert_eq!(node_path, root_path);
    /// ```
    pub fn node_at_path<T: Into<Path>>(&self, path: T) -> Option<NodeId> {
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

    pub fn path_of_node(&self, node_id: NodeId) -> Path {
        let mut path = vec![];
        let mut current_node = node_id;
        // Use .skip(1) on the ancestors iterator to skip the root node.
        let mut ancestors = node_id.ancestors(&self.arena).skip(1);
        while let Some(parent_node) = ancestors.next() {
            let counter = self.index_of_node(parent_node, current_node);
            path.push(counter);
            current_node = parent_node;
        }

        Path(path)
    }

    fn index_of_node(&self, parent_node: NodeId, child_node: NodeId) -> usize {
        let mut counter: usize = 0;
        let mut iter = parent_node.children(&self.arena);
        while let Some(node) = iter.next() {
            if node == child_node {
                return counter;
            }
            counter += 1;
        }

        counter
    }

    ///
    /// # Arguments
    ///
    /// * `node_id`:
    /// * `index`:
    ///
    /// returns: Option<NodeId>
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{NodeOperation, NodeTree, Node, Path};
    /// let node = Node::new("text".to_string());
    /// let inserted_path: Path = vec![0].into();
    ///
    /// let mut node_tree = NodeTree::new();
    /// node_tree.apply_op(&NodeOperation::Insert {path: inserted_path.clone(),nodes: vec![node.clone()] }).unwrap();
    ///
    /// let inserted_note = node_tree.node_at_path(&inserted_path).unwrap();
    /// let inserted_data = node_tree.get_node_data(inserted_note).unwrap();
    /// assert_eq!(inserted_data.node_type, node.node_type);
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

    pub fn children_from_node(&self, node_id: NodeId) -> Children<'_, NodeData> {
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

    pub fn following_siblings(&self, node_id: NodeId) -> FollowingSiblings<'_, NodeData> {
        node_id.following_siblings(&self.arena)
    }

    pub fn apply(&mut self, transaction: Transaction) -> Result<(), OTError> {
        for op in &transaction.operations {
            self.apply_op(op)?;
        }
        Ok(())
    }

    pub fn apply_op(&mut self, op: &NodeOperation) -> Result<(), OTError> {
        match op {
            NodeOperation::Insert { path, nodes } => self.insert_nodes(path, nodes),
            NodeOperation::UpdateAttributes { path, attributes, .. } => self.update_attributes(path, attributes),
            NodeOperation::UpdateBody { path, changeset } => self.update_body(path, changeset),
            NodeOperation::Delete { path, nodes } => self.delete_node(path, nodes),
        }
    }
    /// Inserts nodes at given path
    ///
    /// returns error if the path is empty
    ///
    fn insert_nodes(&mut self, path: &Path, nodes: &[Node]) -> Result<(), OTError> {
        debug_assert!(!path.is_empty());
        if path.is_empty() {
            return Err(OTErrorCode::PathIsEmpty.into());
        }

        let (parent_path, last_path) = path.split_at(path.0.len() - 1);
        let last_index = *last_path.first().unwrap();
        let parent_node = self
            .node_at_path(parent_path)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        self.insert_nodes_at_index(parent_node, last_index, nodes)
    }

    /// Inserts nodes before the node with node_id
    ///
    fn insert_nodes_before(&mut self, node_id: &NodeId, nodes: &[Node]) {
        for node in nodes {
            let new_node_id = self.arena.new_node(node.into());
            if node_id.is_removed(&self.arena) {
                tracing::warn!("Node:{:?} is remove before insert", node_id);
                return;
            }

            node_id.insert_before(new_node_id, &mut self.arena);
            self.append_nodes(&new_node_id, &node.children);
        }
    }

    fn insert_nodes_at_index(&mut self, parent: NodeId, index: usize, insert_children: &[Node]) -> Result<(), OTError> {
        if index == 0 && parent.children(&self.arena).next().is_none() {
            self.append_nodes(&parent, insert_children);
            return Ok(());
        }

        if index == parent.children(&self.arena).count() {
            self.append_nodes(&parent, insert_children);
            return Ok(());
        }

        let node_to_insert = self
            .child_from_node_at_index(parent, index)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        self.insert_nodes_before(&node_to_insert, insert_children);
        Ok(())
    }

    fn append_nodes(&mut self, parent: &NodeId, nodes: &[Node]) {
        for node in nodes {
            let new_node_id = self.arena.new_node(node.into());
            parent.append(new_node_id, &mut self.arena);

            self.append_nodes(&new_node_id, &node.children);
        }
    }

    fn update_attributes(&mut self, path: &Path, attributes: &NodeAttributes) -> Result<(), OTError> {
        self.mut_node_at_path(path, |node_data| {
            let new_attributes = NodeAttributes::compose(&node_data.attributes, attributes)?;
            node_data.attributes = new_attributes;
            Ok(())
        })
    }

    fn delete_node(&mut self, path: &Path, nodes: &[Node]) -> Result<(), OTError> {
        let mut update_node = self
            .node_at_path(path)
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

    fn update_body(&mut self, path: &Path, changeset: &NodeBodyChangeset) -> Result<(), OTError> {
        self.mut_node_at_path(path, |node_data| {
            node_data.apply_body_changeset(changeset);
            Ok(())
        })
    }

    fn mut_node_at_path<F>(&mut self, path: &Path, f: F) -> Result<(), OTError>
    where
        F: Fn(&mut NodeData) -> Result<(), OTError>,
    {
        let node_id = self
            .node_at_path(path)
            .ok_or_else(|| ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        match self.arena.get_mut(node_id) {
            None => tracing::warn!("The path: {:?} does not contain any nodes", path),
            Some(node) => {
                let node_data = node.get_mut();
                let _ = f(node_data)?;
            }
        }
        Ok(())
    }
}
