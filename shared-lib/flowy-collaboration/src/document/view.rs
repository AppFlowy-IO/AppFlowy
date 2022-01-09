use crate::document::*;
use lib_ot::{
    core::{trim, Interval},
    errors::{ErrorBuilder, OTError, OTErrorCode},
    rich_text::{RichTextAttribute, RichTextDelta},
};

pub const RECORD_THRESHOLD: usize = 400; // in milliseconds

pub struct View {
    insert_exts: Vec<InsertExtension>,
    format_exts: Vec<FormatExtension>,
    delete_exts: Vec<DeleteExtension>,
}

impl View {
    pub(crate) fn new() -> Self {
        Self {
            insert_exts: construct_insert_exts(),
            format_exts: construct_format_exts(),
            delete_exts: construct_delete_exts(),
        }
    }

    pub(crate) fn insert(
        &self,
        delta: &RichTextDelta,
        text: &str,
        interval: Interval,
    ) -> Result<RichTextDelta, OTError> {
        let mut new_delta = None;
        for ext in &self.insert_exts {
            if let Some(mut delta) = ext.apply(delta, interval.size(), text, interval.start) {
                trim(&mut delta);
                tracing::debug!("[{} extension]: process: {}", ext.ext_name(), delta);
                new_delta = Some(delta);
                break;
            }
        }

        match new_delta {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyInsertFail).build()),
            Some(new_delta) => Ok(new_delta),
        }
    }

    pub(crate) fn delete(&self, delta: &RichTextDelta, interval: Interval) -> Result<RichTextDelta, OTError> {
        let mut new_delta = None;
        for ext in &self.delete_exts {
            if let Some(mut delta) = ext.apply(delta, interval) {
                trim(&mut delta);
                tracing::trace!("[{}]: applied, delta: {}", ext.ext_name(), delta);
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
        delta: &RichTextDelta,
        attribute: RichTextAttribute,
        interval: Interval,
    ) -> Result<RichTextDelta, OTError> {
        let mut new_delta = None;
        for ext in &self.format_exts {
            if let Some(mut delta) = ext.apply(delta, interval, &attribute) {
                trim(&mut delta);
                tracing::trace!("[{}]: applied, delta: {}", ext.ext_name(), delta);
                new_delta = Some(delta);
                break;
            }
        }

        match new_delta {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyFormatFail).build()),
            Some(new_delta) => Ok(new_delta),
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
