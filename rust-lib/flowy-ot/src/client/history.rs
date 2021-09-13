use crate::core::Delta;

const MAX_UNDOS: usize = 20;

#[derive(Debug, Clone)]
pub struct RevId(pub usize);

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
    len: usize,
}

impl UndoResult {
    pub fn fail() -> Self { UndoResult { success: false, len: 0 } }

    pub fn success(len: usize) -> Self { UndoResult { success: true, len } }
}

#[derive(Debug, Clone)]
pub struct History {
    cur_undo: usize,
    undos: Vec<Delta>,
    redoes: Vec<Delta>,
    capacity: usize,
}

impl History {
    pub fn new() -> Self {
        History {
            cur_undo: 1,
            undos: Vec::new(),
            redoes: Vec::new(),
            capacity: MAX_UNDOS,
        }
    }

    pub fn can_undo(&self) -> bool { !self.undos.is_empty() }

    pub fn can_redo(&self) -> bool { !self.redoes.is_empty() }

    pub fn add_undo(&mut self, delta: Delta) { self.undos.push(delta); }

    pub fn add_redo(&mut self, delta: Delta) { self.redoes.push(delta); }

    pub fn record(&mut self, delta: Delta) {
        if delta.ops.is_empty() {
            return;
        }

        self.redoes.clear();
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

        let delta = self.redoes.pop().unwrap();
        Some(delta)
    }
}
