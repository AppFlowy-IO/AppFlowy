use crate::{
    client::{view::View, History, RevId, UndoResult},
    core::*,
    errors::{ErrorBuilder, OTError, OTErrorCode::*},
};

pub const RECORD_THRESHOLD: usize = 400; // in milliseconds

pub struct Document {
    delta: Delta,
    history: History,
    view: View,
    rev_id_counter: usize,
    last_edit_time: usize,
}

impl Document {
    pub fn new() -> Self {
        let delta = Delta::new();
        Self::from_delta(delta)
    }

    pub fn from_delta(delta: Delta) -> Self {
        Document {
            delta,
            history: History::new(),
            view: View::new(),
            rev_id_counter: 1,
            last_edit_time: 0,
        }
    }

    pub fn insert(
        &mut self,
        index: usize,
        text: &str,
        replace_len: usize,
    ) -> Result<Delta, OTError> {
        if self.delta.target_len < index {
            log::error!(
                "{} out of bounds. should 0..{}",
                index,
                self.delta.target_len
            );
        }

        let delta = self.view.insert(&self.delta, text, index, replace_len)?;
        self.add_delta(&delta)?;
        Ok(delta)
    }

    pub fn delete(&mut self, interval: Interval) -> Result<Delta, OTError> {
        debug_assert_eq!(interval.is_empty(), false);
        let delete = self.view.delete(&self.delta, interval)?;
        if !delete.is_empty() {
            let _ = self.add_delta(&delete)?;
        }
        Ok(delete)
    }

    pub fn format(&mut self, interval: Interval, attribute: Attribute) -> Result<(), OTError> {
        log::debug!("format with {} at {}", attribute, interval);
        let format_delta = self
            .view
            .format(&self.delta, attribute.clone(), interval)
            .unwrap();

        self.add_delta(&format_delta)?;
        Ok(())
    }

    pub fn replace(&mut self, interval: Interval, s: &str) -> Result<Delta, OTError> {
        let mut delta = Delta::default();
        if !s.is_empty() {
            delta = self.insert(interval.start, s, interval.size())?;
        }

        if !interval.is_empty() {
            let delete = self.delete(interval)?;
            delta = delta.compose(&delete)?;
        }

        Ok(delta)
    }

    pub fn can_undo(&self) -> bool { self.history.can_undo() }

    pub fn can_redo(&self) -> bool { self.history.can_redo() }

    pub fn undo(&mut self) -> Result<UndoResult, OTError> {
        match self.history.undo() {
            None => Err(ErrorBuilder::new(UndoFail)
                .msg("Undo stack is empty")
                .build()),
            Some(undo_delta) => {
                let (new_delta, inverted_delta) = self.invert_change(&undo_delta)?;
                let result = UndoResult::success(new_delta.target_len as usize);
                self.delta = new_delta;
                self.history.add_redo(inverted_delta);

                Ok(result)
            },
        }
    }

    pub fn redo(&mut self) -> Result<UndoResult, OTError> {
        match self.history.redo() {
            None => Err(ErrorBuilder::new(RedoFail).build()),
            Some(redo_delta) => {
                let (new_delta, inverted_delta) = self.invert_change(&redo_delta)?;
                let result = UndoResult::success(new_delta.target_len as usize);
                self.delta = new_delta;

                self.history.add_undo(inverted_delta);
                Ok(result)
            },
        }
    }

    pub fn to_json(&self) -> String { self.delta.to_json() }

    pub fn to_string(&self) -> String { self.delta.apply("").unwrap() }

    pub fn data(&self) -> &Delta { &self.delta }

    pub fn set_data(&mut self, data: Delta) { self.delta = data; }

    #[allow(dead_code)]
    fn next_rev_id(&self) -> RevId { RevId(self.rev_id_counter) }

    fn add_delta(&mut self, delta: &Delta) -> Result<(), OTError> {
        log::debug!("👉invert change {}", delta);
        let composed_delta = self.delta.compose(delta)?;
        let mut undo_delta = delta.invert(&self.delta);
        self.rev_id_counter += 1;

        let now = chrono::Utc::now().timestamp_millis() as usize;
        if now - self.last_edit_time < RECORD_THRESHOLD {
            if let Some(last_delta) = self.history.undo() {
                log::debug!("compose previous change");
                log::debug!("current = {}", undo_delta);
                log::debug!("previous = {}", last_delta);
                undo_delta = undo_delta.compose(&last_delta)?;
            }
        } else {
            self.last_edit_time = now;
        }

        log::debug!("compose previous result: {}", undo_delta);
        if !undo_delta.is_empty() {
            self.history.record(undo_delta);
        }

        log::debug!("document delta: {}", &composed_delta);
        self.delta = composed_delta;
        Ok(())
    }

    fn invert_change(&self, change: &Delta) -> Result<(Delta, Delta), OTError> {
        // c = a.compose(b)
        // d = b.invert(a)
        // a = c.compose(d)
        log::debug!("👉invert change {}", change);
        let new_delta = self.delta.compose(change)?;
        let inverted_delta = change.invert(&self.delta);
        // trim(&mut inverted_delta);

        Ok((new_delta, inverted_delta))
    }
}
