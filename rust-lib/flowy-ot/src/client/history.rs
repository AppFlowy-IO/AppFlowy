use crate::core::{Delta, Interval, OpBuilder, Operation};

const MAX_UNDOS: usize = 20;

#[derive(Debug, Clone)]
pub struct Revision {
    rev_id: u64,
    delta: Delta,
}

#[derive(Debug, Clone)]
pub struct UndoResult {
    success: bool,
    len: u64,
}

#[derive(Debug, Clone)]
pub struct History {
    cur_undo: usize,
    undos: Vec<Revision>,
    redos: Vec<Revision>,
}

impl History {
    pub fn new() -> Self {
        History {
            cur_undo: 1,
            undos: Vec::new(),
            redos: Vec::new(),
        }
    }

    pub fn can_undo(&self) -> bool { !self.undos.is_empty() }

    pub fn can_redo(&self) -> bool { !self.redos.is_empty() }

    pub fn record(&mut self, _change: Delta) {}

    pub fn undo(&mut self) -> Option<Revision> {
        if !self.can_undo() {
            return None;
        }

        let revision = self.undos.pop().unwrap();

        Some(revision)
    }

    pub fn redo(&mut self) -> Option<Revision> { None }
}
