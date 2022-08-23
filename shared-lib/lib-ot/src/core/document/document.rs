use crate::core::document::position::Position;
use crate::core::{
    DocumentOperation, NodeAttributes, NodeData, NodeSubTree, OperationTransform, TextDelta, Transaction,
};
use crate::errors::{ErrorBuilder, OTError, OTErrorCode};
use indextree::{Arena, NodeId};

pub struct DocumentTree {
    pub arena: Arena<NodeData>,
    pub root: NodeId,
}

impl DocumentTree {
    pub fn new() -> DocumentTree {
        let mut arena = Arena::new();
        let root = arena.new_node(NodeData::new("root".into()));
        DocumentTree { arena, root }
    }

    pub fn node_at_path(&self, position: &Position) -> Option<NodeId> {
        if position.is_empty() {
            return Some(self.root);
        }

        let mut iterate_node = self.root;

        for id in &position.0 {
            let child = self.child_at_index_of_path(iterate_node, id.clone());
            iterate_node = match child {
                Some(node) => node,
                None => return None,
            };
        }

        Some(iterate_node)
    }

    pub fn path_of_node(&self, node_id: NodeId) -> Position {
        let mut path: Vec<usize> = Vec::new();

        let mut ancestors = node_id.ancestors(&self.arena);
        let mut current_node = node_id;
        let mut parent = ancestors.next();

        while parent.is_some() {
            let parent_node = parent.unwrap();
            let counter = self.index_of_node(parent_node, current_node);
            path.push(counter);
            current_node = parent_node;
            parent = ancestors.next();
        }

        Position(path)
    }

    fn index_of_node(&self, parent_node: NodeId, child_node: NodeId) -> usize {
        let mut counter: usize = 0;

        let mut children_iterator = parent_node.children(&self.arena);
        let mut node = children_iterator.next();

        while node.is_some() {
            if node.unwrap() == child_node {
                return counter;
            }

            node = children_iterator.next();
            counter += 1;
        }

        counter
    }

    fn child_at_index_of_path(&self, at_node: NodeId, index: usize) -> Option<NodeId> {
        let children = at_node.children(&self.arena);

        let mut counter = 0;
        for child in children {
            if counter == index {
                return Some(child);
            }

            counter += 1;
        }

        None
    }

    pub fn apply(&mut self, transaction: Transaction) -> Result<(), OTError> {
        for op in &transaction.operations {
            self.apply_op(op)?;
        }
        Ok(())
    }

    fn apply_op(&mut self, op: &DocumentOperation) -> Result<(), OTError> {
        match op {
            DocumentOperation::Insert { path, nodes } => self.apply_insert(path, nodes),
            DocumentOperation::Update { path, attributes, .. } => self.apply_update(path, attributes),
            DocumentOperation::Delete { path, nodes } => self.apply_delete(path, nodes.len()),
            DocumentOperation::TextEdit { path, delta, .. } => self.apply_text_edit(path, delta),
        }
    }

    fn apply_insert(&mut self, path: &Position, nodes: &Vec<NodeSubTree>) -> Result<(), OTError> {
        let parent_path = &path.0[0..(path.0.len() - 1)];
        let last_index = path.0[path.0.len() - 1];
        let parent_node = self
            .node_at_path(&Position(parent_path.to_vec()))
            .ok_or(ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        // let mut inserted_nodes = Vec::new();
        //
        // for node in nodes {
        //     inserted_nodes.push(self.arena.new_node(node.to_node_data()));
        // }

        self.insert_child_at_index(parent_node, last_index, nodes.as_ref())
    }

    fn insert_child_at_index(
        &mut self,
        parent: NodeId,
        index: usize,
        insert_children: &[NodeSubTree],
    ) -> Result<(), OTError> {
        if index == 0 && parent.children(&self.arena).next().is_none() {
            self.append_subtree(&parent, insert_children);
            return Ok(());
        }

        let children_length = parent.children(&self.arena).fold(0, |counter, _| counter + 1);

        if index == children_length {
            self.append_subtree(&parent, insert_children);
            return Ok(());
        }

        let node_to_insert = self
            .child_at_index_of_path(parent, index)
            .ok_or(ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;

        self.insert_subtree_before(&node_to_insert, insert_children);
        Ok(())
    }

    fn append_subtree(&mut self, parent: &NodeId, insert_children: &[NodeSubTree]) {
        for child in insert_children {
            let child_id = self.arena.new_node(child.to_node_data());
            parent.append(child_id, &mut self.arena);
        }
    }

    fn insert_subtree_before(&mut self, before: &NodeId, insert_children: &[NodeSubTree]) {
        for id in insert_children {
            let child_id = self.arena.new_node(id.to_node_data());
            before.insert_before(child_id, &mut self.arena);
        }
    }

    fn apply_update(&mut self, path: &Position, attributes: &NodeAttributes) -> Result<(), OTError> {
        let update_node = self
            .node_at_path(path)
            .ok_or(ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        let node_data = self.arena.get_mut(update_node).unwrap();
        // let new_node = NodeData {
        //     ..node_data.get().clone()
        //     attributes:
        // };
        let new_node = {
            let old_attributes = &node_data.get().attributes;
            let new_attributes = NodeAttributes::compose(&old_attributes, attributes);
            NodeData {
                attributes: new_attributes,
                ..node_data.get().clone()
            }
        };
        *node_data.get_mut() = new_node;
        Ok(())
    }

    fn apply_delete(&mut self, path: &Position, len: usize) -> Result<(), OTError> {
        let mut update_node = self
            .node_at_path(path)
            .ok_or(ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        for _ in 0..len {
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

    fn apply_text_edit(&mut self, path: &Position, delta: &TextDelta) -> Result<(), OTError> {
        let edit_node = self
            .node_at_path(path)
            .ok_or(ErrorBuilder::new(OTErrorCode::PathNotFound).build())?;
        let node_data = self.arena.get_mut(edit_node).unwrap();
        let new_delta = if let Some(old_delta) = &node_data.get().delta {
            Some(old_delta.compose(delta)?)
        } else {
            None
        };
        if let Some(new_delta) = new_delta {
            *node_data.get_mut() = NodeData {
                delta: Some(new_delta),
                ..node_data.get().clone()
            };
        };
        Ok(())
    }
}
