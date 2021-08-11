use crate::{
    client::view::{DeleteExt, FormatExt, InsertExt, *},
    core::{Attribute, Delta, Interval},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};

type InsertExtension = Box<dyn InsertExt>;
type FormatExtension = Box<dyn FormatExt>;
type DeleteExtension = Box<dyn DeleteExt>;

pub struct View {
    insert_exts: Vec<InsertExtension>,
    format_exts: Vec<FormatExtension>,
    delete_exts: Vec<DeleteExtension>,
}

impl View {
    pub(crate) fn new() -> Self {
        let insert_exts = construct_insert_exts();
        let format_exts = construct_format_exts();
        let delete_exts = construct_delete_exts();
        Self {
            insert_exts,
            format_exts,
            delete_exts,
        }
    }

    pub(crate) fn insert(&self, delta: &Delta, text: &str, index: usize) -> Result<Delta, OTError> {
        let mut new_delta = None;
        for ext in &self.insert_exts {
            if let Some(delta) = ext.apply(delta, 0, text, index) {
                new_delta = Some(delta);
                break;
            }
        }

        match new_delta {
            None => Err(ErrorBuilder::new(OTErrorCode::ApplyInsertFail).build()),
            Some(new_delta) => Ok(new_delta),
        }
    }

    pub(crate) fn replace(
        &self,
        delta: &Delta,
        text: &str,
        interval: Interval,
    ) -> Result<Delta, OTError> {
        unimplemented!()
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
        Box::new(PreserveInlineStyleExt::new()),
        Box::new(ResetLineFormatOnNewLineExt::new()),
    ]
}

fn construct_format_exts() -> Vec<FormatExtension> {
    vec![
        Box::new(FormatLinkAtCaretPositionExt {}),
        Box::new(ResolveLineFormatExt {}),
        Box::new(ResolveInlineFormatExt {}),
    ]
}

fn construct_delete_exts() -> Vec<DeleteExtension> {
    vec![
        //

    ]
}
