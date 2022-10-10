use crate::client_document::*;
use lib_ot::core::AttributeEntry;
use lib_ot::{
    core::{trim, Interval},
    errors::{ErrorBuilder, OTError, OTErrorCode},
    text_delta::TextOperations,
};

pub const RECORD_THRESHOLD: usize = 400; // in milliseconds

pub struct ViewExtensions {
    insert_exts: Vec<InsertExtension>,
    format_exts: Vec<FormatExtension>,
    delete_exts: Vec<DeleteExtension>,
}

impl ViewExtensions {
    pub(crate) fn new() -> Self {
        Self {
            insert_exts: construct_insert_exts(),
            format_exts: construct_format_exts(),
            delete_exts: construct_delete_exts(),
        }
    }

    pub(crate) fn insert(
        &self,
        operations: &TextOperations,
        text: &str,
        interval: Interval,
    ) -> Result<TextOperations, OTError> {
        let mut new_operations = None;
        for ext in &self.insert_exts {
            if let Some(mut operations) = ext.apply(operations, interval.size(), text, interval.start) {
                trim(&mut operations);
                tracing::trace!("[{}] applied, delta: {}", ext.ext_name(), operations);
                new_operations = Some(operations);
                break;
            }
        }

        match new_operations {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyInsertFail).build()),
            Some(new_operations) => Ok(new_operations),
        }
    }

    pub(crate) fn delete(&self, delta: &TextOperations, interval: Interval) -> Result<TextOperations, OTError> {
        let mut new_delta = None;
        for ext in &self.delete_exts {
            if let Some(mut delta) = ext.apply(delta, interval) {
                trim(&mut delta);
                tracing::trace!("[{}] applied, delta: {}", ext.ext_name(), delta);
                new_delta = Some(delta);
                break;
            }
        }

        match new_delta {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyDeleteFail).build()),
            Some(new_delta) => Ok(new_delta),
        }
    }

    pub(crate) fn format(
        &self,
        operations: &TextOperations,
        attribute: AttributeEntry,
        interval: Interval,
    ) -> Result<TextOperations, OTError> {
        let mut new_operations = None;
        for ext in &self.format_exts {
            if let Some(mut operations) = ext.apply(operations, interval, &attribute) {
                trim(&mut operations);
                tracing::trace!("[{}] applied, delta: {}", ext.ext_name(), operations);
                new_operations = Some(operations);
                break;
            }
        }

        match new_operations {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyFormatFail).build()),
            Some(new_operations) => Ok(new_operations),
        }
    }
}

fn construct_insert_exts() -> Vec<InsertExtension> {
    vec![
        Box::new(InsertEmbedsExt {}),
        Box::new(ForceNewlineForInsertsAroundEmbedExt {}),
        Box::new(AutoExitBlock {}),
        Box::new(PreserveBlockFormatOnInsert {}),
        Box::new(PreserveLineFormatOnSplit {}),
        Box::new(ResetLineFormatOnNewLine {}),
        Box::new(AutoFormatExt {}),
        Box::new(PreserveInlineFormat {}),
        Box::new(DefaultInsertAttribute {}),
    ]
}

fn construct_format_exts() -> Vec<FormatExtension> {
    vec![
        // Box::new(FormatLinkAtCaretPositionExt {}),
        Box::new(ResolveBlockFormat {}),
        Box::new(ResolveInlineFormat {}),
    ]
}

fn construct_delete_exts() -> Vec<DeleteExtension> {
    vec![Box::new(PreserveLineFormatOnMerge {}), Box::new(DefaultDelete {})]
}
