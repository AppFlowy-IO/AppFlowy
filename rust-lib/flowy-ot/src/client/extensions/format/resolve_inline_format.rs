use crate::{
    client::{
        extensions::{format::helper::line_break, FormatExt},
        util::find_newline,
    },
    core::{Attribute, AttributeScope, Delta, DeltaBuilder, DeltaIter, Interval},
};

pub struct ResolveInlineFormat {}
impl FormatExt for ResolveInlineFormat {
    fn ext_name(&self) -> &str { std::any::type_name::<ResolveInlineFormat>() }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Inline {
            return None;
        }
        let mut new_delta = DeltaBuilder::new().retain(interval.start).build();
        let mut iter = DeltaIter::from_offset(delta, interval.start);
        let mut start = 0;
        let end = interval.size();

        while start < end && iter.has_next() {
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.len(), attribute.clone().into()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Inline);
                    new_delta.extend(tmp_delta);
                },
            }

            start += next_op.len();
        }

        Some(new_delta)
    }
}
