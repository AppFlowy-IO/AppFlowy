use crate::{
    client_document::{
        history::{History, UndoResult},
        view::{ViewExtensions, RECORD_THRESHOLD},
    },
    errors::CollaborateError,
};
use bytes::Bytes;
use flowy_http_model::util::md5;
use lib_ot::text_delta::DeltaTextOperationBuilder;
use lib_ot::{core::*, text_delta::DeltaTextOperations};
use tokio::sync::mpsc;

pub trait InitialDocument {
    fn json_str() -> String;
}

pub struct EmptyDocument();
impl InitialDocument for EmptyDocument {
    fn json_str() -> String {
        DeltaTextOperations::default().json_str()
    }
}

pub struct NewlineDocument();
impl InitialDocument for NewlineDocument {
    fn json_str() -> String {
        initial_delta_document_content()
    }
}

pub fn initial_delta_document_content() -> String {
    DeltaTextOperationBuilder::new().insert("\n").build().json_str()
}

pub struct ClientDocument {
    operations: DeltaTextOperations,
    history: History,
    view: ViewExtensions,
    last_edit_time: usize,
    notify: Option<mpsc::UnboundedSender<()>>,
}

impl ClientDocument {
    pub fn new<C: InitialDocument>() -> Self {
        let content = C::json_str();
        Self::from_json(&content).unwrap()
    }

    pub fn from_operations(operations: DeltaTextOperations) -> Self {
        ClientDocument {
            operations,
            history: History::new(),
            view: ViewExtensions::new(),
            last_edit_time: 0,
            notify: None,
        }
    }

    pub fn from_json(json: &str) -> Result<Self, CollaborateError> {
        let operations = DeltaTextOperations::from_json(json)?;
        Ok(Self::from_operations(operations))
    }

    pub fn get_operations_json(&self) -> String {
        self.operations.json_str()
    }

    pub fn to_bytes(&self) -> Bytes {
        self.operations.json_bytes()
    }

    pub fn to_content(&self) -> String {
        self.operations.content().unwrap()
    }

    pub fn get_operations(&self) -> &DeltaTextOperations {
        &self.operations
    }

    pub fn document_md5(&self) -> String {
        let bytes = self.to_bytes();
        md5(&bytes)
    }

    pub fn set_notify(&mut self, notify: mpsc::UnboundedSender<()>) {
        self.notify = Some(notify);
    }

    pub fn set_operations(&mut self, operations: DeltaTextOperations) {
        tracing::trace!("document: {}", operations.json_str());
        self.operations = operations;

        match &self.notify {
            None => {}
            Some(notify) => {
                let _ = notify.send(());
            }
        }
    }

    pub fn compose_operations(&mut self, operations: DeltaTextOperations) -> Result<(), CollaborateError> {
        tracing::trace!("{} compose {}", &self.operations.json_str(), operations.json_str());
        let composed_operations = self.operations.compose(&operations)?;
        let mut undo_operations = operations.invert(&self.operations);

        let now = chrono::Utc::now().timestamp_millis() as usize;
        if now - self.last_edit_time < RECORD_THRESHOLD {
            if let Some(last_operation) = self.history.undo() {
                tracing::trace!("compose previous change");
                tracing::trace!("current = {}", undo_operations);
                tracing::trace!("previous = {}", last_operation);
                undo_operations = undo_operations.compose(&last_operation)?;
            }
        } else {
            self.last_edit_time = now;
        }

        if !undo_operations.is_empty() {
            tracing::trace!("add history operations: {}", undo_operations);
            self.history.record(undo_operations);
        }

        self.set_operations(composed_operations);
        Ok(())
    }

    pub fn insert<T: ToString>(&mut self, index: usize, data: T) -> Result<DeltaTextOperations, CollaborateError> {
        let text = data.to_string();
        let interval = Interval::new(index, index);
        validate_interval(&self.operations, &interval)?;
        let operations = self.view.insert(&self.operations, &text, interval)?;
        self.compose_operations(operations.clone())?;
        Ok(operations)
    }

    pub fn delete(&mut self, interval: Interval) -> Result<DeltaTextOperations, CollaborateError> {
        validate_interval(&self.operations, &interval)?;
        debug_assert!(!interval.is_empty());
        let operations = self.view.delete(&self.operations, interval)?;
        if !operations.is_empty() {
            self.compose_operations(operations.clone())?;
        }
        Ok(operations)
    }

    pub fn format(
        &mut self,
        interval: Interval,
        attribute: AttributeEntry,
    ) -> Result<DeltaTextOperations, CollaborateError> {
        validate_interval(&self.operations, &interval)?;
        tracing::trace!("format {} with {:?}", interval, attribute);
        let operations = self.view.format(&self.operations, attribute, interval).unwrap();
        self.compose_operations(operations.clone())?;
        Ok(operations)
    }

    pub fn replace<T: ToString>(
        &mut self,
        interval: Interval,
        data: T,
    ) -> Result<DeltaTextOperations, CollaborateError> {
        validate_interval(&self.operations, &interval)?;
        let mut operations = DeltaTextOperations::default();
        let text = data.to_string();
        if !text.is_empty() {
            operations = self.view.insert(&self.operations, &text, interval)?;
            self.compose_operations(operations.clone())?;
        }

        if !interval.is_empty() {
            let delete = self.delete(interval)?;
            operations = operations.compose(&delete)?;
        }

        Ok(operations)
    }

    pub fn can_undo(&self) -> bool {
        self.history.can_undo()
    }

    pub fn can_redo(&self) -> bool {
        self.history.can_redo()
    }

    pub fn undo(&mut self) -> Result<UndoResult, CollaborateError> {
        match self.history.undo() {
            None => Err(CollaborateError::undo().context("Undo stack is empty")),
            Some(undo_operations) => {
                let (new_operations, inverted_operations) = self.invert(&undo_operations)?;
                self.set_operations(new_operations);
                self.history.add_redo(inverted_operations);
                Ok(UndoResult {
                    operations: undo_operations,
                })
            }
        }
    }

    pub fn redo(&mut self) -> Result<UndoResult, CollaborateError> {
        match self.history.redo() {
            None => Err(CollaborateError::redo()),
            Some(redo_operations) => {
                let (new_operations, inverted_operations) = self.invert(&redo_operations)?;
                self.set_operations(new_operations);
                self.history.add_undo(inverted_operations);
                Ok(UndoResult {
                    operations: redo_operations,
                })
            }
        }
    }

    pub fn is_empty(&self) -> bool {
        // The document is empty if its text is equal to the initial text.
        self.operations.json_str() == NewlineDocument::json_str()
    }
}

impl ClientDocument {
    fn invert(
        &self,
        operations: &DeltaTextOperations,
    ) -> Result<(DeltaTextOperations, DeltaTextOperations), CollaborateError> {
        // c = a.compose(b)
        // d = b.invert(a)
        // a = c.compose(d)
        let new_operations = self.operations.compose(operations)?;
        let inverted_operations = operations.invert(&self.operations);
        Ok((new_operations, inverted_operations))
    }
}

fn validate_interval(operations: &DeltaTextOperations, interval: &Interval) -> Result<(), CollaborateError> {
    if operations.utf16_target_len < interval.end {
        log::error!(
            "{:?} out of bounds. should 0..{}",
            interval,
            operations.utf16_target_len
        );
        return Err(CollaborateError::out_of_bound());
    }
    Ok(())
}
