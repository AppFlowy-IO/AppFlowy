use crate::{
    client::view::*,
    core::{Attribute, Delta, Interval, Operation},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};

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
        delta: &Delta,
        text: &str,
        interval: Interval,
    ) -> Result<Delta, OTError> {
        let mut new_delta = None;
        for ext in &self.insert_exts {
            if let Some(delta) = ext.apply(delta, interval.size(), text, interval.start) {
                log::debug!("[{}]: applied, delta: {}", ext.ext_name(), delta);
                new_delta = Some(delta);
                break;
            }
        }

        match new_delta {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyInsertFail).build()),
            Some(new_delta) => Ok(new_delta),
        }
    }

    pub(crate) fn delete(&self, delta: &Delta, interval: Interval) -> Result<Delta, OTError> {
        let mut new_delta = None;
        for ext in &self.delete_exts {
            if let Some(delta) = ext.apply(delta, interval) {
                log::debug!("[{}]: applied, delta: {}", ext.ext_name(), delta);
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
        delta: &Delta,
        attribute: Attribute,
        interval: Interval,
    ) -> Result<Delta, OTError> {
        let mut new_delta = None;
        for ext in &self.format_exts {
            if let Some(delta) = ext.apply(delta, interval, &attribute) {
                log::debug!("[{}]: applied, delta: {}", ext.ext_name(), delta);
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
        Box::new(AutoExitBlockExt {}),
        Box::new(PreserveBlockStyleOnInsertExt {}),
        Box::new(PreserveLineStyleOnSplitExt {}),
        Box::new(ResetLineFormatOnNewLineExt {}),
        Box::new(AutoFormatLinksExt {}),
        Box::new(PreserveInlineStylesExt {}),
        Box::new(DefaultInsertExt {}),
    ]
}

fn construct_format_exts() -> Vec<FormatExtension> {
    vec![
        Box::new(FormatLinkAtCaretPositionExt {}),
        Box::new(ResolveBlockFormatExt {}),
        Box::new(ResolveInlineFormatExt {}),
    ]
}

fn construct_delete_exts() -> Vec<DeleteExtension> {
    vec![
        //
        Box::new(DefaultDeleteExt {}),
    ]
}
