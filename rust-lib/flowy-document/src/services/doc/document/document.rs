use crate::{
    errors::DocError,
    services::doc::{view::View, History, UndoResult, RECORD_THRESHOLD},
};
use bytes::Bytes;
use flowy_ot::core::*;
use std::convert::TryInto;

pub trait DocumentData {
    fn into_string(self) -> Result<String, DocError>;
}

pub trait CustomDocument {
    fn init_delta() -> Delta;
}

pub struct PlainDoc();
impl CustomDocument for PlainDoc {
    fn init_delta() -> Delta { Delta::new() }
}

pub struct FlowyDoc();
impl CustomDocument for FlowyDoc {
    fn init_delta() -> Delta { DeltaBuilder::new().insert("\n").build() }
}

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

pub struct Document {
    delta: Delta,
    history: History,
    view: View,
    rev_id_counter: usize,
    last_edit_time: usize,
}

impl Document {
    pub fn new<C: CustomDocument>() -> Self { Self::from_delta(C::init_delta()) }

    pub fn from_delta(delta: Delta) -> Self {
        Document {
            delta,
            history: History::new(),
            view: View::new(),
            rev_id_counter: 1,
            last_edit_time: 0,
        }
    }

    pub fn from_json(json: &str) -> Result<Self, DocError> {
        let delta = Delta::from_json(json)?;
        Ok(Self::from_delta(delta))
    }

    pub fn to_json(&self) -> String { self.delta.to_json() }

    pub fn to_bytes(&self) -> Vec<u8> { self.delta.clone().into_bytes() }

    pub fn to_string(&self) -> String { self.delta.apply("").unwrap() }

    pub fn apply_delta(&mut self, data: Bytes) -> Result<(), DocError> {
        let new_delta = Delta::from_bytes(data.to_vec())?;

        log::debug!("Apply delta: {}", new_delta);

        let rev_id = self.next_rev_id();
        let revision = Revision::new(rev_id, new_delta.clone());

        let _ = self.add_delta(&new_delta)?;
        log::debug!("Document: {}", self.to_json());
        Ok(())
    }

    pub fn insert<T: DocumentData>(&mut self, index: usize, data: T) -> Result<Delta, DocError> {
        let interval = Interval::new(index, index);
        let _ = validate_interval(&self.delta, &interval)?;

        let text = data.into_string()?;
        let delta = self.view.insert(&self.delta, &text, interval)?;
        log::trace!("👉 receive change: {}", delta);
        self.add_delta(&delta)?;
        Ok(delta)
    }

    pub fn delete(&mut self, interval: Interval) -> Result<Delta, DocError> {
        let _ = validate_interval(&self.delta, &interval)?;
        debug_assert_eq!(interval.is_empty(), false);
        let delete = self.view.delete(&self.delta, interval)?;
        if !delete.is_empty() {
            log::trace!("👉 receive change: {}", delete);
            let _ = self.add_delta(&delete)?;
        }
        Ok(delete)
    }

    pub fn format(&mut self, interval: Interval, attribute: Attribute) -> Result<(), DocError> {
        let _ = validate_interval(&self.delta, &interval)?;
        log::trace!("format with {} at {}", attribute, interval);
        let format_delta = self.view.format(&self.delta, attribute.clone(), interval).unwrap();

        log::trace!("👉 receive change: {}", format_delta);
        self.add_delta(&format_delta)?;
        Ok(())
    }

    pub fn replace<T: DocumentData>(&mut self, interval: Interval, data: T) -> Result<Delta, DocError> {
        let _ = validate_interval(&self.delta, &interval)?;
        let mut delta = Delta::default();
        let text = data.into_string()?;
        if !text.is_empty() {
            delta = self.view.insert(&self.delta, &text, interval)?;
            log::trace!("👉 receive change: {}", delta);
            self.add_delta(&delta)?;
        }

        if !interval.is_empty() {
            let delete = self.delete(interval)?;
            delta = delta.compose(&delete)?;
        }

        Ok(delta)
    }

    pub fn can_undo(&self) -> bool { self.history.can_undo() }

    pub fn can_redo(&self) -> bool { self.history.can_redo() }

    pub fn undo(&mut self) -> Result<UndoResult, DocError> {
        match self.history.undo() {
            None => Err(DocError::undo().context("Undo stack is empty")),
            Some(undo_delta) => {
                let (new_delta, inverted_delta) = self.invert_change(&undo_delta)?;
                let result = UndoResult::success(new_delta.target_len as usize);
                self.delta = new_delta;
                self.history.add_redo(inverted_delta);

                Ok(result)
            },
        }
    }

    pub fn redo(&mut self) -> Result<UndoResult, DocError> {
        match self.history.redo() {
            None => Err(DocError::redo()),
            Some(redo_delta) => {
                let (new_delta, inverted_delta) = self.invert_change(&redo_delta)?;
                let result = UndoResult::success(new_delta.target_len as usize);
                self.delta = new_delta;

                self.history.add_undo(inverted_delta);
                Ok(result)
            },
        }
    }

    pub fn data(&self) -> &Delta { &self.delta }

    pub fn set_data(&mut self, data: Delta) { self.delta = data; }
}

impl Document {
    fn add_delta(&mut self, delta: &Delta) -> Result<(), DocError> {
        let composed_delta = self.delta.compose(delta)?;
        let mut undo_delta = delta.invert(&self.delta);
        self.rev_id_counter += 1;

        let now = chrono::Utc::now().timestamp_millis() as usize;
        if now - self.last_edit_time < RECORD_THRESHOLD {
            if let Some(last_delta) = self.history.undo() {
                log::trace!("compose previous change");
                log::trace!("current = {}", undo_delta);
                log::trace!("previous = {}", last_delta);
                undo_delta = undo_delta.compose(&last_delta)?;
            }
        } else {
            self.last_edit_time = now;
        }

        log::trace!("👉 receive change undo: {}", undo_delta);
        if !undo_delta.is_empty() {
            self.history.record(undo_delta);
        }

        log::trace!("document delta: {}", &composed_delta);
        self.delta = composed_delta;
        Ok(())
    }

    fn invert_change(&self, change: &Delta) -> Result<(Delta, Delta), DocError> {
        // c = a.compose(b)
        // d = b.invert(a)
        // a = c.compose(d)
        log::trace!("👉invert change {}", change);
        let new_delta = self.delta.compose(change)?;
        let inverted_delta = change.invert(&self.delta);
        Ok((new_delta, inverted_delta))
    }

    #[allow(dead_code)]
    fn next_rev_id(&self) -> RevId { RevId(self.rev_id_counter) }
}

fn validate_interval(delta: &Delta, interval: &Interval) -> Result<(), DocError> {
    if delta.target_len < interval.end {
        log::error!("{:?} out of bounds. should 0..{}", interval, delta.target_len);
        return Err(DocError::out_of_bound());
    }
    Ok(())
}
