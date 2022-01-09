use crate::{
    document::{
        default::initial_delta,
        history::{History, UndoResult},
        view::{View, RECORD_THRESHOLD},
    },
    errors::CollaborateError,
};
use lib_ot::{
    core::*,
    rich_text::{RichTextAttribute, RichTextDelta},
};
use tokio::sync::mpsc;

pub trait InitialDocumentText {
    fn initial_delta() -> RichTextDelta;
}

pub struct PlainDoc();
impl InitialDocumentText for PlainDoc {
    fn initial_delta() -> RichTextDelta { RichTextDelta::new() }
}

pub struct NewlineDoc();
impl InitialDocumentText for NewlineDoc {
    fn initial_delta() -> RichTextDelta { initial_delta() }
}

pub struct Document {
    delta: RichTextDelta,
    history: History,
    view: View,
    last_edit_time: usize,
    notify: Option<mpsc::UnboundedSender<()>>,
}

impl Document {
    pub fn new<C: InitialDocumentText>() -> Self { Self::from_delta(C::initial_delta()) }

    pub fn from_delta(delta: RichTextDelta) -> Self {
        Document {
            delta,
            history: History::new(),
            view: View::new(),
            last_edit_time: 0,
            notify: None,
        }
    }

    pub fn from_json(json: &str) -> Result<Self, CollaborateError> {
        let delta = RichTextDelta::from_json(json)?;
        Ok(Self::from_delta(delta))
    }

    pub fn to_json(&self) -> String { self.delta.to_json() }

    pub fn to_bytes(&self) -> Vec<u8> { self.delta.clone().to_bytes().to_vec() }

    pub fn to_plain_string(&self) -> String { self.delta.apply("").unwrap() }

    pub fn delta(&self) -> &RichTextDelta { &self.delta }

    pub fn md5(&self) -> String {
        // TODO: Optimize the cost of calculating the md5
        let bytes = self.to_bytes();
        format!("{:x}", md5::compute(bytes))
    }

    pub fn set_notify(&mut self, notify: mpsc::UnboundedSender<()>) { self.notify = Some(notify); }

    pub fn set_delta(&mut self, data: RichTextDelta) {
        tracing::trace!("document: {}", data.to_json());
        self.delta = data;

        match &self.notify {
            None => {},
            Some(notify) => {
                let _ = notify.send(());
            },
        }
    }

    pub fn compose_delta(&mut self, delta: RichTextDelta) -> Result<(), CollaborateError> {
        tracing::trace!("{} compose {}", &self.delta.to_json(), delta.to_json());
        let composed_delta = self.delta.compose(&delta)?;
        let mut undo_delta = delta.invert(&self.delta);

        let now = chrono::Utc::now().timestamp_millis() as usize;
        if now - self.last_edit_time < RECORD_THRESHOLD {
            if let Some(last_delta) = self.history.undo() {
                tracing::trace!("compose previous change");
                tracing::trace!("current = {}", undo_delta);
                tracing::trace!("previous = {}", last_delta);
                undo_delta = undo_delta.compose(&last_delta)?;
            }
        } else {
            self.last_edit_time = now;
        }

        if !undo_delta.is_empty() {
            tracing::trace!("add history delta: {}", undo_delta);
            self.history.record(undo_delta);
        }

        self.set_delta(composed_delta);
        Ok(())
    }

    pub fn insert<T: ToString>(&mut self, index: usize, data: T) -> Result<RichTextDelta, CollaborateError> {
        let text = data.to_string();
        let interval = Interval::new(index, index);
        let _ = validate_interval(&self.delta, &interval)?;
        let delta = self.view.insert(&self.delta, &text, interval)?;
        self.compose_delta(delta.clone())?;
        Ok(delta)
    }

    pub fn delete(&mut self, interval: Interval) -> Result<RichTextDelta, CollaborateError> {
        let _ = validate_interval(&self.delta, &interval)?;
        debug_assert_eq!(interval.is_empty(), false);
        let delete = self.view.delete(&self.delta, interval)?;
        if !delete.is_empty() {
            let _ = self.compose_delta(delete.clone())?;
        }
        Ok(delete)
    }

    pub fn format(
        &mut self,
        interval: Interval,
        attribute: RichTextAttribute,
    ) -> Result<RichTextDelta, CollaborateError> {
        let _ = validate_interval(&self.delta, &interval)?;
        tracing::trace!("format {} with {}", interval, attribute);
        let format_delta = self.view.format(&self.delta, attribute, interval).unwrap();
        self.compose_delta(format_delta.clone())?;
        Ok(format_delta)
    }

    pub fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<RichTextDelta, CollaborateError> {
        let _ = validate_interval(&self.delta, &interval)?;
        let mut delta = RichTextDelta::default();
        let text = data.to_string();
        if !text.is_empty() {
            delta = self.view.insert(&self.delta, &text, interval)?;
            self.compose_delta(delta.clone())?;
        }

        if !interval.is_empty() {
            let delete = self.delete(interval)?;
            delta = delta.compose(&delete)?;
        }

        Ok(delta)
    }

    pub fn can_undo(&self) -> bool { self.history.can_undo() }

    pub fn can_redo(&self) -> bool { self.history.can_redo() }

    pub fn undo(&mut self) -> Result<UndoResult, CollaborateError> {
        match self.history.undo() {
            None => Err(CollaborateError::undo().context("Undo stack is empty")),
            Some(undo_delta) => {
                let (new_delta, inverted_delta) = self.invert(&undo_delta)?;
                self.set_delta(new_delta);
                self.history.add_redo(inverted_delta);
                Ok(UndoResult { delta: undo_delta })
            },
        }
    }

    pub fn redo(&mut self) -> Result<UndoResult, CollaborateError> {
        match self.history.redo() {
            None => Err(CollaborateError::redo()),
            Some(redo_delta) => {
                let (new_delta, inverted_delta) = self.invert(&redo_delta)?;
                self.set_delta(new_delta);
                self.history.add_undo(inverted_delta);
                Ok(UndoResult { delta: redo_delta })
            },
        }
    }

    pub fn is_empty<C: InitialDocumentText>(&self) -> bool { self.delta == C::initial_delta() }
}

impl Document {
    fn invert(&self, delta: &RichTextDelta) -> Result<(RichTextDelta, RichTextDelta), CollaborateError> {
        // c = a.compose(b)
        // d = b.invert(a)
        // a = c.compose(d)
        let new_delta = self.delta.compose(delta)?;
        let inverted_delta = delta.invert(&self.delta);
        Ok((new_delta, inverted_delta))
    }
}

fn validate_interval(delta: &RichTextDelta, interval: &Interval) -> Result<(), CollaborateError> {
    if delta.utf16_target_len < interval.end {
        log::error!("{:?} out of bounds. should 0..{}", interval, delta.utf16_target_len);
        return Err(CollaborateError::out_of_bound());
    }
    Ok(())
}
