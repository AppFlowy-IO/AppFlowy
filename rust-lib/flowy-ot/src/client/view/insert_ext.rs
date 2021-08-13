use crate::{
    client::view::InsertExt,
    core::{
        attributes_with_length,
        AttributeKey,
        Attributes,
        CharMetric,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Operation,
    },
};

pub const NEW_LINE: &'static str = "\n";

pub struct PreserveBlockStyleOnInsertExt {}
impl InsertExt for PreserveBlockStyleOnInsertExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct PreserveLineStyleOnSplitExt {}
impl InsertExt for PreserveLineStyleOnSplitExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct AutoExitBlockExt {}

impl InsertExt for AutoExitBlockExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct InsertEmbedsExt {}
impl InsertExt for InsertEmbedsExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct ForceNewlineForInsertsAroundEmbedExt {}
impl InsertExt for ForceNewlineForInsertsAroundEmbedExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct AutoFormatLinksExt {}
impl InsertExt for AutoFormatLinksExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        None
    }
}

pub struct PreserveInlineStylesExt {}
impl InsertExt for PreserveInlineStylesExt {
    fn apply(&self, delta: &Delta, _replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text.ends_with(NEW_LINE) {
            return None;
        }
        let probe_index = if index > 1 { index - 1 } else { index };
        let attributes = attributes_with_length(delta, probe_index);
        let delta = DeltaBuilder::new().insert(text, attributes).build();

        Some(delta)
    }
}

pub struct ResetLineFormatOnNewLineExt {}
impl InsertExt for ResetLineFormatOnNewLineExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text != NEW_LINE {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(index);
        let maybe_next_op = iter.next();
        if maybe_next_op.is_none() {
            return None;
        }

        let op = maybe_next_op.unwrap();
        if !op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = Attributes::new();
        if op.get_attributes().contains_key(&AttributeKey::Header) {
            reset_attribute.add(AttributeKey::Header.with_value(""));
        }

        let len = index + replace_len;
        Some(
            DeltaBuilder::new()
                .retain(len, Attributes::default())
                .insert(NEW_LINE, op.get_attributes())
                .retain(1, reset_attribute)
                .trim()
                .build(),
        )
    }
}

pub struct DefaultInsertExt {}
impl InsertExt for DefaultInsertExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        Some(
            DeltaBuilder::new()
                .retain(index + replace_len, Attributes::default())
                .insert(text, Attributes::default())
                .build(),
        )
    }
}
