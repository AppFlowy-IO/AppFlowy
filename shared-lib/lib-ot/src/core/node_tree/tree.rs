use super::NodeOperations;
use crate::core::{Changeset, Node, NodeData, NodeOperation, Path, Transaction};
use crate::errors::{OTError, OTErrorCode};
use indextree::{Arena, FollowingSiblings, NodeId};
use std::sync::Arc;

#[derive(Default, Debug, Clone)]
pub struct NodeTreeContext {}

#[derive(Debug, Clone)]
pub struct NodeTree {
  arena: Arena<Node>,
  root: NodeId,
  pub context: NodeTreeContext,
}

impl Default for NodeTree {
  fn default() -> Self {
    Self::new(NodeTreeContext::default())
  }
}

pub const PLACEHOLDER_NODE_TYPE: &str = "";

impl NodeTree {
  pub fn new(context: NodeTreeContext) -> NodeTree {
    let mut arena = Arena::new();
    let root = arena.new_node(Node::new("root"));
    NodeTree {
      arena,
      root,
      context,
    }
  }

  pub fn from_node_data(node_data: NodeData, context: NodeTreeContext) -> Result<Self, OTError> {
    let mut tree = Self::new(context);
    tree.insert_nodes(&0_usize.into(), vec![node_data])?;
    Ok(tree)
  }

  pub fn from_bytes(bytes: &[u8]) -> Result<Self, OTError> {
    let tree: NodeTree = serde_json::from_slice(bytes).map_err(|e| OTError::serde().context(e))?;
    Ok(tree)
  }

  pub fn to_bytes(&self) -> Vec<u8> {
    match serde_json::to_vec(self) {
      Ok(bytes) => bytes,
      Err(e) => {
        tracing::error!("{}", e);
        vec![]
      },
    }
  }

  pub fn to_json(&self, pretty: bool) -> Result<String, OTError> {
    if pretty {
      match serde_json::to_string_pretty(self) {
        Ok(json) => Ok(json),
        Err(err) => Err(OTError::serde().context(err)),
      }
    } else {
      match serde_json::to_string(self) {
        Ok(json) => Ok(json),
        Err(err) => Err(OTError::serde().context(err)),
      }
    }
  }

  pub fn from_operations<T: Into<NodeOperations>>(
    operations: T,
    context: NodeTreeContext,
  ) -> Result<Self, OTError> {
    let operations = operations.into();
    let mut node_tree = NodeTree::new(context);
    for (_, operation) in operations.into_inner().into_iter().enumerate() {
      node_tree.apply_op(operation)?;
    }
    Ok(node_tree)
  }

  pub fn from_transaction<T: Into<Transaction>>(
    transaction: T,
    context: NodeTreeContext,
  ) -> Result<Self, OTError> {
    let transaction = transaction.into();
    let mut tree = Self::new(context);
    tree.apply_transaction(transaction)?;
    Ok(tree)
  }

  pub fn get_node(&self, node_id: NodeId) -> Option<&Node> {
    if node_id.is_removed(&self.arena) {
      return None;
    }
    Some(self.arena.get(node_id)?.get())
  }

  pub fn get_node_at_path(&self, path: &Path) -> Option<&Node> {
    let node_id = self.node_id_at_path(path)?;
    self.get_node(node_id)
  }

  pub fn get_node_data_at_path(&self, path: &Path) -> Option<NodeData> {
    let node_id = self.node_id_at_path(path)?;
    let node_data = self.get_node_data(node_id)?;
    Some(node_data)
  }

  pub fn get_node_data_at_root(&self) -> Option<NodeData> {
    self.get_node_data(self.root)
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

    let children = self.get_children_ids(node_id);
    for child in children.into_iter() {
      if let Some(child_node_data) = self.get_node_data(child) {
        node_data.children.push(child_node_data);
      }
    }
    Some(node_data)
  }

  pub fn root_node_id(&self) -> NodeId {
    self.root
  }

  pub fn get_children(&self, node_id: NodeId) -> Vec<&Node> {
    node_id
      .children(&self.arena)
      .flat_map(|node_id| self.get_node(node_id))
      .collect()
  }
  /// Returns a iterator used to iterate over the node ids whose parent node id is node_id
  ///
  /// * `node_id`: the children's parent node id
  ///
  pub fn get_children_ids(&self, node_id: NodeId) -> Vec<NodeId> {
    node_id.children(&self.arena).collect()
  }

  /// Serialize the node to JSON with node_id
  pub fn serialize_node(&self, node_id: NodeId, pretty_json: bool) -> Result<String, OTError> {
    let node_data = self
      .get_node_data(node_id)
      .ok_or_else(|| OTError::internal().context("Node doesn't exist exist"))?;
    if pretty_json {
      serde_json::to_string_pretty(&node_data).map_err(|err| OTError::serde().context(err))
    } else {
      serde_json::to_string(&node_data).map_err(|err| OTError::serde().context(err))
    }
  }

  ///
  /// # Examples
  ///
  /// ```
  /// use std::sync::Arc;
  /// use lib_ot::core::{NodeOperation, NodeTree, NodeData, Path};
  /// let nodes = vec![NodeData::new("text".to_string())];
  /// let root_path: Path = vec![0].into();
  /// let op = NodeOperation::Insert {path: root_path.clone(),nodes };
  ///
  /// let mut node_tree = NodeTree::default();
  /// node_tree.apply_op(Arc::new(op)).unwrap();
  /// let node_id = node_tree.node_id_at_path(&root_path).unwrap();
  /// let node_path = node_tree.path_from_node_id(node_id);
  /// debug_assert_eq!(node_path, root_path);
  /// ```
  pub fn node_id_at_path<T: Into<Path>>(&self, path: T) -> Option<NodeId> {
    let path = path.into();
    if !path.is_valid() {
      return None;
    }

    let mut node_id = self.root;
    for id in path.iter() {
      node_id = self.node_id_from_parent_at_index(node_id, *id)?;
    }

    if node_id.is_removed(&self.arena) {
      return None;
    }
    Some(node_id)
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
    path.reverse();
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

  /// Returns the note_id at the index of the tree which its id is note_id
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
  /// use std::sync::Arc;
  /// use lib_ot::core::{NodeOperation, NodeTree, NodeData, Path};
  /// let node_1 = NodeData::new("text".to_string());
  /// let inserted_path: Path = vec![0].into();
  ///
  /// let mut node_tree = NodeTree::default();
  /// let op = NodeOperation::Insert {path: inserted_path.clone(),nodes: vec![node_1.clone()] };
  /// node_tree.apply_op(Arc::new(op)).unwrap();
  ///
  /// let node_2 = node_tree.get_node_at_path(&inserted_path).unwrap();
  /// assert_eq!(node_2.node_type, node_1.node_type);
  /// ```
  pub fn node_id_from_parent_at_index(&self, node_id: NodeId, index: usize) -> Option<NodeId> {
    let children = node_id.children(&self.arena);
    for (counter, child) in children.enumerate() {
      if counter == index {
        return Some(child);
      }
    }

    None
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
    let operations = transaction.split().0;
    for operation in operations {
      self.apply_op(operation)?;
    }

    Ok(())
  }

  pub fn apply_op<T: Into<Arc<NodeOperation>>>(&mut self, op: T) -> Result<(), OTError> {
    let op = match Arc::try_unwrap(op.into()) {
      Ok(op) => op,
      Err(op) => op.as_ref().clone(),
    };

    match op {
      NodeOperation::Insert { path, nodes } => self.insert_nodes(&path, nodes),
      NodeOperation::Update { path, changeset } => self.update(&path, changeset),
      NodeOperation::Delete { path, nodes } => {
        if nodes.is_empty() {
          self.delete_node(&path)
        } else {
          self.delete_nodes(&path, nodes)
        }
      },
    }
  }
  /// Inserts nodes at given path
  /// root
  ///     0 - A
  ///         0 - A1
  ///     1 - B
  ///         0 - B1
  ///         1 - B2
  ///
  /// The path of each node will be:
  /// A:      [0]
  /// A1:     [0,0]
  /// B:      [1]
  /// B1:     [1,0]
  /// B2:     [1,1]
  ///
  /// When inserting multiple nodes into the same path, each of them will be appended to the root
  /// node. For example. The path is [0] and the nodes are [A, B, C]. After inserting the nodes,
  /// the tree will be:
  /// root
  ///     0: A
  ///     1: B
  ///     2: C
  ///
  /// returns error if the path is empty
  ///
  fn insert_nodes(&mut self, path: &Path, nodes: Vec<NodeData>) -> Result<(), OTError> {
    if !path.is_valid() {
      return Err(OTErrorCode::InvalidPath.into());
    }

    let (parent_path, last_path) = path.split_at(path.0.len() - 1);
    let last_index = *last_path.first().unwrap();
    if parent_path.is_empty() {
      self.insert_nodes_at_index(self.root, last_index, nodes)
    } else {
      let parent_node = match self.node_id_at_path(parent_path) {
        None => self.create_adjacent_nodes_for_path(parent_path),
        Some(parent_node) => parent_node,
      };

      self.insert_nodes_at_index(parent_node, last_index, nodes)
    }
  }

  /// Create the adjacent nodes for the path
  ///
  /// It will create a corresponding node for each node on the path if it's not existing.
  /// If the path is not start from zero, it will create its siblings.
  ///
  /// Check out the operation_insert_test.rs for more examples.
  /// * operation_insert_node_when_its_parent_is_not_exist
  /// * operation_insert_node_when_multiple_parent_is_not_exist_test
  ///
  /// # Arguments
  ///
  /// * `path`: creates nodes for this path
  ///
  /// returns: NodeId
  ///
  fn create_adjacent_nodes_for_path<T: Into<Path>>(&mut self, path: T) -> NodeId {
    let path = path.into();
    let mut node_id = self.root;
    for id in path.iter() {
      match self.node_id_from_parent_at_index(node_id, *id) {
        None => {
          let num_of_children = node_id.children(&self.arena).count();
          if *id > num_of_children {
            for _ in 0..(*id - num_of_children) {
              let node: Node = placeholder_node().into();
              let sibling_node = self.arena.new_node(node);
              node_id.append(sibling_node, &mut self.arena);
            }
          }

          let node: Node = placeholder_node().into();
          let new_node_id = self.arena.new_node(node);
          node_id.append(new_node_id, &mut self.arena);
          node_id = new_node_id;
        },
        Some(next_node_id) => {
          node_id = next_node_id;
        },
      }
    }
    node_id
  }

  /// Inserts nodes before the node with node_id
  ///
  fn insert_nodes_before(&mut self, node_id: &NodeId, nodes: Vec<NodeData>) {
    if node_id.is_removed(&self.arena) {
      tracing::warn!("Node:{:?} is remove before insert", node_id);
      return;
    }
    for node in nodes {
      let (node, children) = node.split();
      let new_node_id = self.arena.new_node(node);
      node_id.insert_before(new_node_id, &mut self.arena);
      self.append_nodes(&new_node_id, children);
    }
  }

  fn insert_nodes_at_index(
    &mut self,
    parent: NodeId,
    index: usize,
    nodes: Vec<NodeData>,
  ) -> Result<(), OTError> {
    if index == 0 && parent.children(&self.arena).next().is_none() {
      self.append_nodes(&parent, nodes);
      return Ok(());
    }

    // Append the node to the end of the children list if index greater or equal to the
    // length of the children.
    let num_of_children = parent.children(&self.arena).count();
    if index >= num_of_children {
      let mut num_of_nodes_to_insert = index - num_of_children;
      while num_of_nodes_to_insert > 0 {
        self.append_nodes(&parent, vec![placeholder_node()]);
        num_of_nodes_to_insert -= 1;
      }

      self.append_nodes(&parent, nodes);
      return Ok(());
    }

    let node_to_insert = self
      .node_id_from_parent_at_index(parent, index)
      .ok_or_else(|| OTError::internal().context(format!("Can't find the node at {}", index)))?;

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

  /// Removes a node and its descendants from the tree
  fn delete_node(&mut self, path: &Path) -> Result<(), OTError> {
    if !path.is_valid() {
      return Err(OTErrorCode::InvalidPath.into());
    }
    match self.node_id_at_path(path) {
      None => tracing::warn!("Can't find any node at path: {:?}", path),
      Some(node) => {
        node.remove_subtree(&mut self.arena);
      },
    }

    Ok(())
  }

  /// Removes a node and the consecutive nodes behide it
  ///
  /// if the nodes is empty, it will remove the single node at the path.
  /// else it will remove the nodes at the path and the consecutive nodes behind it.
  fn delete_nodes(&mut self, path: &Path, nodes: Vec<NodeData>) -> Result<(), OTError> {
    if !path.is_valid() {
      return Err(OTErrorCode::InvalidPath.into());
    }

    let node_id = self.node_id_at_path(path).ok_or_else(|| {
      tracing::warn!("Can't find any node at path: {:?}", path);
      OTError::internal().context("Can't find any node at path")
    });

    if node_id.is_err() {
      return Err(OTErrorCode::PathNotFound.into());
    }

    for _ in 0..nodes.len() {
      let res = self.delete_node(path);
      res?
    }

    Ok(())
  }

  /// Update the node at path with the `changeset`
  ///
  /// Do nothing if there is no node at the path.
  ///
  /// # Arguments
  ///
  /// * `path`: references to the node that will be applied with the changeset
  /// * `changeset`: the change that will be applied to the node
  ///
  /// returns: Result<(), OTError>
  fn update(&mut self, path: &Path, changeset: Changeset) -> Result<(), OTError> {
    match self.mut_node_at_path(path, |node| node.apply_changeset(changeset)) {
      Ok(_) => {},
      Err(err) => tracing::error!("{}", err),
    }
    Ok(())
  }

  fn mut_node_at_path<F>(&mut self, path: &Path, f: F) -> Result<(), OTError>
  where
    F: FnOnce(&mut Node) -> Result<(), OTError>,
  {
    if !path.is_valid() {
      return Err(OTErrorCode::InvalidPath.into());
    }
    let node_id = self.node_id_at_path(path).ok_or_else(|| {
      OTError::path_not_found().context(format!("Can't find the mutated node at path: {:?}", path))
    })?;
    match self.arena.get_mut(node_id) {
      None => tracing::warn!("The path: {:?} does not contain any nodes", path),
      Some(node) => {
        let node = node.get_mut();
        f(node)?;
      },
    }
    Ok(())
  }
}

pub fn placeholder_node() -> NodeData {
  NodeData::new(PLACEHOLDER_NODE_TYPE)
}
