use crate::{
    client::{History, RevId, UndoResult},
    core::*,
    errors::{ErrorBuilder, OTError, OTErrorCode::*},
};

pub const RECORD_THRESHOLD: usize = 400; // in milliseconds

pub struct Document {
    data: Delta,
    history: History,
    rev_id_counter: usize,
    last_edit_time: usize,
}

impl Document {
    pub fn new() -> Self {
        let delta = Delta::new();
        Document {
            data: delta,
            history: History::new(),
            rev_id_counter: 1,
            last_edit_time: 0,
        }
    }

    pub fn edit(&mut self, index: usize, text: &str) -> Result<(), OTError> {
        if self.data.target_len < index {
            log::error!(
                "{} out of bounds. should 0..{}",
                index,
                self.data.target_len
            );
        }
        let probe = Interval::new(index, index + 1);
        let mut attributes = self.data.get_attributes(probe);
        if attributes.is_empty() {
            attributes = Attributes::Follow;
        }
        let mut delta = Delta::new();
        let insert = Builder::insert(text).attributes(attributes).build();
        let interval = Interval::new(index, index);
        delta.add(insert);

        self.update_with_op(&delta, interval)
    }

    pub fn format(
        &mut self,
        interval: Interval,
        attribute: Attribute,
        enable: bool,
    ) -> Result<(), OTError> {
        let attributes = match enable {
            true => AttrsBuilder::new().add(attribute).build(),
            false => AttrsBuilder::new().remove(&attribute).build(),
        };
        log::debug!("format with {} at {}", attributes, interval);
        self.update_with_attribute(attributes, interval)
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
                self.data = new_delta;
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
                self.data = new_delta;

                self.history.add_undo(inverted_delta);
                Ok(result)
            },
        }
    }

    pub fn replace(&mut self, interval: Interval, s: &str) -> Result<(), OTError> {
        let mut delta = Delta::default();
        if !s.is_empty() {
            let insert = Builder::insert(s).attributes(Attributes::Follow).build();
            delta.add(insert);
        }

        if !interval.is_empty() {
            let delete = Builder::delete(interval.size()).build();
            delta.add(delete);
        }

        self.update_with_op(&delta, interval)
    }

    pub fn to_json(&self) -> String { self.data.to_json() }

    pub fn to_string(&self) -> String { self.data.apply("").unwrap() }

    pub fn data(&self) -> &Delta { &self.data }

    pub fn set_data(&mut self, data: Delta) { self.data = data; }

    fn update_with_op(&mut self, delta: &Delta, interval: Interval) -> Result<(), OTError> {
        let mut new_delta = Delta::default();
        let (prefix, interval, suffix) = split_length_with_interval(self.data.target_len, interval);

        // prefix
        if prefix.is_empty() == false && prefix != interval {
            let intervals = split_interval_with_delta(&self.data, &prefix);
            intervals.into_iter().for_each(|i| {
                let attributes = self.data.get_attributes(i);
                log::trace!("prefix attribute: {:?}, interval: {:?}", attributes, i);
                new_delta.retain(i.size() as usize, attributes);
            });
        }

        delta.ops.iter().for_each(|op| {
            new_delta.add(op.clone());
        });

        // suffix
        if suffix.is_empty() == false {
            let intervals = split_interval_with_delta(&self.data, &suffix);
            intervals.into_iter().for_each(|i| {
                let attributes = self.data.get_attributes(i);
                log::trace!("suffix attribute: {:?}, interval: {:?}", attributes, i);
                new_delta.retain(i.size() as usize, attributes);
            });
        }

        self.data = self.record_change(&new_delta)?;
        Ok(())
    }

    pub fn update_with_attribute(
        &mut self,
        mut attributes: Attributes,
        interval: Interval,
    ) -> Result<(), OTError> {
        log::debug!("Update document with attributes: {:?}", attributes,);
        let old_attributes = self.data.get_attributes(interval);
        log::debug!("combine with old: {:?}", old_attributes);
        let new_attributes = match &mut attributes {
            Attributes::Follow => old_attributes,
            Attributes::Custom(attr_data) => {
                attr_data.merge(old_attributes.data());
                log::debug!("combine with old result : {:?}", attr_data);
                attr_data.clone().into()
            },
        };

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
        let new_delta = self.data.compose(change)?;
        let inverted_delta = change.invert(&self.data);
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

fn split_interval_with_delta(delta: &Delta, interval: &Interval) -> Vec<Interval> {
    let mut start = 0;
    let mut new_intervals = vec![];
    delta.ops.iter().for_each(|op| match op {
        Operation::Delete(_) => {},
        Operation::Retain(_) => {},
        Operation::Insert(insert) => {
            let len = insert.num_chars() as usize;
            let end = start + len;
            let insert_interval = Interval::new(start, end);
            let new_interval = interval.intersect(insert_interval);

            if !new_interval.is_empty() {
                new_intervals.push(new_interval)
            }
            start += len;
        },
    });
    new_intervals
}

pub fn trim(delta: &mut Delta) {
    let remove_last = match delta.ops.last() {
        None => false,
        Some(op) => match op {
            Operation::Delete(_) => false,
            Operation::Retain(retain) => retain.is_plain(),
            Operation::Insert(_) => false,
        },
    };
    if remove_last {
        delta.ops.pop();
    }
}
