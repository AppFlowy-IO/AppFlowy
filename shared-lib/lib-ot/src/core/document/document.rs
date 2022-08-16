use crate::core::document::position::Position;
use crate::core::NodeData;
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
}
