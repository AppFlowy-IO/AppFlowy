use crate::core::document::position::Position;
use crate::core::{DeleteOperation, DocumentOperation, InsertOperation, NodeData, TextEditOperation, Transaction, UpdateOperation};
use indextree::{Arena, NodeId};

pub struct DocumentTree {
    arena: Arena<NodeData>,
    root: NodeId,
}

impl DocumentTree {
    pub fn new() -> DocumentTree {
        let mut arena = Arena::new();
        let root = arena.new_node(NodeData::new("root".into()));
        DocumentTree {
            arena: Arena::new(),
            root,
        }
    }

    pub fn node_at_path(&self, position: &Position) -> Option<NodeId> {
        if position.is_empty() {
            return None;
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

    pub fn apply(&mut self, transaction: Transaction) {
        for op in &transaction.operations {
            self.apply_op(op);
        }
    }

    fn apply_op(&mut self, op: &DocumentOperation) {
        match op  {
            DocumentOperation::Insert(op) => self.apply_insert(op),
            DocumentOperation::Update(op) => self.apply_update(op),
            DocumentOperation::Delete(op) => self.apply_delete(op),
            DocumentOperation::TextEdit(op) => self.apply_text_edit(op),
        }
    }

    fn apply_insert(&mut self, op: &InsertOperation) {
        let parent_path = &op.path.0[0..(op.path.0.len() - 1)];
        let last_index = op.path.0[op.path.0.len() - 1];
        let parent_node = self.node_at_path(&Position(parent_path.to_vec()));
        if let Some(parent_node) = parent_node {
            self.insert_child_at_index(parent_node, last_index, &op.nodes);
        }
    }

    fn insert_child_at_index(&mut self, parent: NodeId, index: usize, insert_children: &[NodeId]) {
        if index == 0 && insert_children.len() == 0 {
            for id in insert_children {
                parent.append(*id, &mut self.arena);
            }
            return;
        }

        let node_to_insert = self.child_at_index_of_path(parent, index).unwrap();

        for id in insert_children {
            node_to_insert.insert_before(*id, &mut self.arena);
        }
    }

    fn apply_update(&self, _op: &UpdateOperation) {
        unimplemented!()
    }

    fn apply_delete(&self, _op: &DeleteOperation) {
        unimplemented!()
    }

    fn apply_text_edit(&self, _op: &TextEditOperation) {
        unimplemented!()
    }
}
