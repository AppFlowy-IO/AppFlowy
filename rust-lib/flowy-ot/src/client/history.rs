use crate::core::Delta;

const MAX_UNDOS: usize = 20;

#[derive(Debug, Clone)]
pub struct RevId(pub u64);

#[derive(Debug, Clone)]
pub struct Revision {
    rev_id: RevId,
    pub delta: Delta,
}

impl Revision {
    pub fn new(rev_id: RevId, delta: Delta) -> Revision { Self { rev_id, delta } }
}

#[derive(Debug, Clone)]
pub struct UndoResult {
    success: bool,
    len: u64,
}

impl UndoResult {
    pub fn fail() -> Self {
        UndoResult {
            success: false,
            len: 0,
        }
    }

    pub fn success(len: u64) -> Self { UndoResult { success: true, len } }
}

#[derive(Debug, Clone)]
pub struct History {
    cur_undo: usize,
    undos: Vec<Delta>,
    redos: Vec<Delta>,
    capacity: usize,
}

impl History {
    pub fn new() -> Self {
        History {
            cur_undo: 1,
            undos: Vec::new(),
            redos: Vec::new(),
            capacity: 20,
        }
    }

    pub fn can_undo(&self) -> bool { !self.undos.is_empty() }

    pub fn can_redo(&self) -> bool { !self.redos.is_empty() }

    pub fn add_undo(&mut self, delta: Delta) { self.undos.push(delta); }

    pub fn add_redo(&mut self, delta: Delta) { self.redos.push(delta); }

    pub fn record(&mut self, delta: Delta) {
        if delta.ops.is_empty() {
            return;
        }

        self.redos.clear();
        self.add_undo(delta);

        if self.undos.len() > self.capacity {
            self.undos.remove(0);
        }
    }

    pub fn undo(&mut self) -> Option<Delta> {
        if !self.can_undo() {
            return None;
        }
        let delta = self.undos.pop().unwrap();
        Some(delta)
    }

    pub fn redo(&mut self) -> Option<Delta> {
        if !self.can_redo() {
            return None;
        }

        let delta = self.redos.pop().unwrap();
        Some(delta)
    }
}
