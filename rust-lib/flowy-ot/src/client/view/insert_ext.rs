use crate::{
    client::view::InsertExt,
    core::{AttributeKey, Attributes, CharMetric, Delta, DeltaBuilder, DeltaIter},
};

pub const NEW_LINE: &'static str = "\n";

pub struct PreserveBlockStyleOnInsertExt {}
impl InsertExt for PreserveBlockStyleOnInsertExt {
    fn ext_name(&self) -> &str { "PreserveBlockStyleOnInsertExt" }

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
    fn ext_name(&self) -> &str { "PreserveLineStyleOnSplitExt" }

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
    fn ext_name(&self) -> &str { "AutoExitBlockExt" }

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
    fn ext_name(&self) -> &str { "InsertEmbedsExt" }

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
    fn ext_name(&self) -> &str { "ForceNewlineForInsertsAroundEmbedExt" }

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
    fn ext_name(&self) -> &str { "AutoFormatLinksExt" }

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
    fn ext_name(&self) -> &str { "PreserveInlineStylesExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text.contains(NEW_LINE) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.next_op_before(index)?;
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
    fn ext_name(&self) -> &str { "ResetLineFormatOnNewLineExt" }

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
            reset_attribute.add(AttributeKey::Header.value(""));
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
    fn ext_name(&self) -> &str { "DefaultInsertExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        let iter = DeltaIter::new(delta);
        let mut attributes = Attributes::new();

        // Enable each line split by "\n" remains the block attributes. for example:
        // insert "\n" to "123456" at index 3
        //
        // [{"insert":"123"},{"insert":"\n","attributes":{"header":"1"}},
        // {"insert":"456"},{"insert":"\n","attributes":{"header":"1"}}]
        if text.ends_with(NEW_LINE) {
            match iter.last() {
                None => {},
                Some(op) => {
                    if op.get_attributes().contains_key(&AttributeKey::Header) {
                        attributes.extend(op.get_attributes());
                    }
                },
            }
        }

        Some(
            DeltaBuilder::new()
                .retain(index + replace_len)
                .insert_with_attributes(text, attributes)
                .build(),
        )
    }
}
