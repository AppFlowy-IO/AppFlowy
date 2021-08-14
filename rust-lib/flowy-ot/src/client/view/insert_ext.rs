use crate::{
    client::view::InsertExt,
    core::{AttributeKey, Attributes, CharMetric, Delta, DeltaBuilder, DeltaIter},
};

pub const NEW_LINE: &'static str = "\n";

pub struct PreserveBlockStyleOnInsertExt {}
impl InsertExt for PreserveBlockStyleOnInsertExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct PreserveLineStyleOnSplitExt {}
impl InsertExt for PreserveLineStyleOnSplitExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct AutoExitBlockExt {}

impl InsertExt for AutoExitBlockExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct InsertEmbedsExt {}
impl InsertExt for InsertEmbedsExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct ForceNewlineForInsertsAroundEmbedExt {}
impl InsertExt for ForceNewlineForInsertsAroundEmbedExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct AutoFormatLinksExt {}
impl InsertExt for AutoFormatLinksExt {
    fn apply(
        &self,
        _delta: &Delta,
        _replace_len: usize,
        _text: &str,
        _index: usize,
    ) -> Option<Delta> {
        None
    }
}

pub struct PreserveInlineStylesExt {}
impl InsertExt for PreserveInlineStylesExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text.ends_with(NEW_LINE) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.next_op_with_len(index)?;
        if prev.get_data().contains(NEW_LINE) {
            return None;
        }

        let mut attributes = prev.get_attributes();
        if attributes.is_empty() || !attributes.contains_key(&AttributeKey::Link) {
            return Some(
                DeltaBuilder::new()
                    .retain(index + replace_len)
                    .insert_with_attributes(text, attributes)
                    .build(),
            );
        }

        attributes.remove(&AttributeKey::Link);
        let new_delta = DeltaBuilder::new()
            .retain(index + replace_len)
            .insert_with_attributes(text, attributes)
            .build();

        return Some(new_delta);
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
        let next_op = iter.next()?;
        if !next_op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = Attributes::new();
        if next_op.get_attributes().contains_key(&AttributeKey::Header) {
            reset_attribute.add(AttributeKey::Header.with_value(""));
        }

        let len = index + replace_len;
        Some(
            DeltaBuilder::new()
                .retain(len)
                .insert_with_attributes(NEW_LINE, next_op.get_attributes())
                .retain_with_attributes(1, reset_attribute)
                .trim()
                .build(),
        )
    }
}

pub struct DefaultInsertExt {}
impl InsertExt for DefaultInsertExt {
    fn apply(&self, _delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        Some(
            DeltaBuilder::new()
                .retain(index + replace_len)
                .insert(text)
                .build(),
        )
    }
}
