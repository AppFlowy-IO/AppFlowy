use lib_ot::text_delta::DeltaTextOperations;

const MAX_UNDOES: usize = 20;

#[derive(Debug, Clone)]
pub struct UndoResult {
    pub operations: DeltaTextOperations,
}

#[derive(Debug, Clone)]
pub struct History {
    #[allow(dead_code)]
    cur_undo: usize,
    undoes: Vec<DeltaTextOperations>,
    redoes: Vec<DeltaTextOperations>,
    capacity: usize,
}

impl std::default::Default for History {
    fn default() -> Self {
        History {
            cur_undo: 1,
            undoes: Vec::new(),
            redoes: Vec::new(),
            capacity: MAX_UNDOES,
        }
    }
}

impl History {
    pub fn new() -> Self {
        History::default()
    }

    pub fn can_undo(&self) -> bool {
        !self.undoes.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.redoes.is_empty()
    }

    pub fn add_undo(&mut self, delta: DeltaTextOperations) {
        self.undoes.push(delta);
    }

    pub fn add_redo(&mut self, delta: DeltaTextOperations) {
        self.redoes.push(delta);
    }

    pub fn record(&mut self, delta: DeltaTextOperations) {
        if delta.ops.is_empty() {
            return;
        }

        self.redoes.clear();
        self.add_undo(delta);

        if self.undoes.len() > self.capacity {
            self.undoes.remove(0);
        }
    }

    pub fn undo(&mut self) -> Option<DeltaTextOperations> {
        if !self.can_undo() {
            return None;
        }
        let delta = self.undoes.pop().unwrap();
        Some(delta)
    }

    pub fn redo(&mut self) -> Option<DeltaTextOperations> {
        if !self.can_redo() {
            return None;
        }

        let delta = self.redoes.pop().unwrap();
        Some(delta)
    }
}
