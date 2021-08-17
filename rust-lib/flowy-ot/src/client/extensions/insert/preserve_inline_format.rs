use crate::{
    client::{
        extensions::InsertExt,
        util::{contain_newline, is_newline},
    },
    core::{
        AttributeKey,
        Attributes,
        Delta,
        DeltaBuilder,
        DeltaIter,
        OpNewline,
        Operation,
        NEW_LINE,
    },
};

pub struct PreserveInlineFormat {}
impl InsertExt for PreserveInlineFormat {
    fn ext_name(&self) -> &str { std::any::type_name::<PreserveInlineFormat>() }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if contain_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.last_op_before_index(index)?;
        if OpNewline::parse(&prev).is_contain() {
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

        let next = iter.next_op();
        match &next {
            None => attributes = Attributes::empty(),
            Some(next) => {
                if OpNewline::parse(&next).is_equal() {
                    attributes = Attributes::empty();
                }
            },
        }

        let new_delta = DeltaBuilder::new()
            .retain(index + replace_len)
            .insert_with_attributes(text, attributes)
            .build();

        return Some(new_delta);
    }
}

pub struct PreserveLineFormatOnSplit {}
impl InsertExt for PreserveLineFormatOnSplit {
    fn ext_name(&self) -> &str { std::any::type_name::<PreserveLineFormatOnSplit>() }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.last_op_before_index(index)?;
        if OpNewline::parse(&prev).is_end() {
            return None;
        }

        let next = iter.next_op()?;
        let newline_status = OpNewline::parse(&next);
        if newline_status.is_end() {
            return None;
        }

        let mut new_delta = Delta::new();
        new_delta.retain(index + replace_len, Attributes::empty());

        if newline_status.is_contain() {
            debug_assert!(next.has_attribute() == false);
            new_delta.insert(NEW_LINE, Attributes::empty());
            return Some(new_delta);
        }

        match iter.first_newline_op() {
            None => {},
            Some((newline_op, _)) => {
                new_delta.insert(NEW_LINE, newline_op.get_attributes());
            },
        }

        Some(new_delta)
    }
}
