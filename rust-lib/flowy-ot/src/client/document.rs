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

    pub fn insert(&mut self, index: usize, text: &str) -> Result<(), OTError> {
        if self.delta.target_len < index {
            log::error!(
                "{} out of bounds. should 0..{}",
                index,
                self.delta.target_len
            );
        }

        let delta = self.view.insert(&self.delta, text, index)?;
        let interval = Interval::new(index, index);
        self.update_with_op(&delta, interval)
    }

    pub fn format(&mut self, interval: Interval, attribute: Attribute) -> Result<(), OTError> {
        log::debug!("format with {} at {}", attribute, interval);

        self.update_with_attribute(attribute, interval)
    }

    pub fn replace(&mut self, interval: Interval, s: &str) -> Result<(), OTError> {
        let mut delta = Delta::default();
        if !s.is_empty() {
            let insert = Builder::insert(s).build();
            delta.add(insert);
        }

        if !interval.is_empty() {
            let delete = Builder::delete(interval.size()).build();
            delta.add(delete);
        }

        self.update_with_op(&delta, interval)
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

    fn update_with_op(&mut self, delta: &Delta, interval: Interval) -> Result<(), OTError> {
        let mut new_delta = Delta::default();
        let (prefix, interval, suffix) =
            split_length_with_interval(self.delta.target_len, interval);

        // prefix
        if prefix.is_empty() == false && prefix != interval {
            AttributesIter::from_interval(&self.delta, prefix).for_each(|(length, attributes)| {
                log::debug!("prefix attribute: {:?}, len: {}", attributes, length);
                new_delta.retain(length, attributes);
            });
        }

        delta.ops.iter().for_each(|op| {
            new_delta.add(op.clone());
        });

        // suffix
        if suffix.is_empty() == false {
            AttributesIter::from_interval(&self.delta, suffix).for_each(|(length, attributes)| {
                log::debug!("suffix attribute: {:?}, len: {}", attributes, length);
                new_delta.retain(length, attributes);
            });
        }

        self.delta = self.record_change(&new_delta)?;
        Ok(())
    }

    pub fn update_with_attribute(
        &mut self,
        attribute: Attribute,
        interval: Interval,
    ) -> Result<(), OTError> {
        log::debug!("Update document with attribute: {}", attribute);
        let mut attributes = AttrsBuilder::new().add(attribute).build();
        let old_attributes = AttributesIter::from_interval(&self.delta, interval).next_or_empty();

        log::debug!("combine with old: {:?}", old_attributes);
        attributes.merge(Some(old_attributes));
        let new_attributes = attributes;
        log::debug!("combine result: {:?}", new_attributes);

        let retain = Builder::retain(interval.size())
            .attributes(new_attributes)
            .build();

        let mut delta = Delta::new();
        delta.add(retain);

        self.update_with_op(&delta, interval)
    }

    fn next_rev_id(&self) -> RevId { RevId(self.rev_id_counter) }

    fn record_change(&mut self, delta: &Delta) -> Result<Delta, OTError> {
        let (composed_delta, mut undo_delta) = self.invert_change(&delta)?;
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

        if !undo_delta.is_empty() {
            log::debug!("record change: {}", undo_delta);
            self.history.record(undo_delta);
        }

        log::debug!("document delta: {}", &composed_delta);
        Ok(composed_delta)
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

fn split_length_with_interval(length: usize, interval: Interval) -> (Interval, Interval, Interval) {
    let original_interval = Interval::new(0, length);
    let prefix = original_interval.prefix(interval);
    let suffix = original_interval.suffix(interval);
    (prefix, interval, suffix)
}
