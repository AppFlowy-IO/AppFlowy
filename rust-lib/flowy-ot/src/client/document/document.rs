use crate::{
    client::{view::View, History, RevId, UndoResult, RECORD_THRESHOLD},
    core::*,
    errors::{ErrorBuilder, OTError, OTErrorCode, OTErrorCode::*},
};

pub trait DocumentData {
    fn into_string(self) -> Result<String, OTError>;
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

    pub fn from_json(json: &str) -> Result<Self, OTError> {
        let delta = Delta::from_json(json)?;
        Ok(Self::from_delta(delta))
    }

    pub fn to_json(&self) -> String { self.delta.to_json() }

    pub fn insert<T: DocumentData>(&mut self, index: usize, data: T) -> Result<Delta, OTError> {
        let interval = Interval::new(index, index);
        let _ = validate_interval(&self.delta, &interval)?;

        let text = data.into_string()?;
        let delta = self.view.insert(&self.delta, &text, interval)?;
        log::debug!("👉 receive change: {}", delta);
        self.add_delta(&delta)?;
        Ok(delta)
    }

    pub fn delete(&mut self, interval: Interval) -> Result<Delta, OTError> {
        let _ = validate_interval(&self.delta, &interval)?;
        debug_assert_eq!(interval.is_empty(), false);
        let delete = self.view.delete(&self.delta, interval)?;
        if !delete.is_empty() {
            log::debug!("👉 receive change: {}", delete);
            let _ = self.add_delta(&delete)?;
        }
        Ok(delete)
    }

    pub fn format(&mut self, interval: Interval, attribute: Attribute) -> Result<(), OTError> {
        let _ = validate_interval(&self.delta, &interval)?;
        log::debug!("format with {} at {}", attribute, interval);
        let format_delta = self.view.format(&self.delta, attribute.clone(), interval).unwrap();

        log::debug!("👉 receive change: {}", format_delta);
        self.add_delta(&format_delta)?;
        Ok(())
    }

    pub fn replace<T: DocumentData>(&mut self, interval: Interval, data: T) -> Result<Delta, OTError> {
        let _ = validate_interval(&self.delta, &interval)?;
        let mut delta = Delta::default();
        let text = data.into_string()?;
        if !text.is_empty() {
            delta = self.view.insert(&self.delta, &text, interval)?;
            log::debug!("👉 receive change: {}", delta);
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

    pub fn undo(&mut self) -> Result<UndoResult, OTError> {
        match self.history.undo() {
            None => Err(ErrorBuilder::new(UndoFail).msg("Undo stack is empty").build()),
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

    pub fn to_string(&self) -> String { self.delta.apply("").unwrap() }

    pub fn data(&self) -> &Delta { &self.delta }

    pub fn set_data(&mut self, data: Delta) { self.delta = data; }
}

impl Document {
    fn add_delta(&mut self, delta: &Delta) -> Result<(), OTError> {
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

        log::debug!("👉 receive change undo: {}", undo_delta);
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
        Ok((new_delta, inverted_delta))
    }

    #[allow(dead_code)]
    fn next_rev_id(&self) -> RevId { RevId(self.rev_id_counter) }
}

fn validate_interval(delta: &Delta, interval: &Interval) -> Result<(), OTError> {
    if delta.target_len < interval.end {
        log::error!("{:?} out of bounds. should 0..{}", interval, delta.target_len);
        return Err(ErrorBuilder::new(OTErrorCode::IntervalOutOfBound).build());
    }
    Ok(())
}
