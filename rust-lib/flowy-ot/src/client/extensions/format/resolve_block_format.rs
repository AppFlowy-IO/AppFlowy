use crate::{
    client::{
        extensions::{format::helper::line_break, FormatExt},
        util::find_newline,
    },
    core::{
        Attribute,
        AttributeScope,
        Attributes,
        CharMetric,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Interval,
    },
};

pub struct ResolveBlockFormatExt {}
impl FormatExt for ResolveBlockFormatExt {
    fn ext_name(&self) -> &str { "ResolveBlockFormatExt" }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Block {
            return None;
        }

        let mut new_delta = DeltaBuilder::new().retain(interval.start).build();
        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);
        let mut start = 0;
        let end = interval.size();
        while start < end && iter.has_next() {
            let next_op = iter.next_op_before(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.len(), Attributes::empty()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Block);
                    new_delta.extend(tmp_delta);
                },
            }

            start += next_op.len();
        }

        while iter.has_next() {
            let op = iter
                .next_op()
                .expect("Unexpected None, iter.has_next() must return op");

            match find_newline(op.get_data()) {
                None => new_delta.retain(op.len(), Attributes::empty()),
                Some(line_break) => {
                    debug_assert_eq!(line_break, 0);
                    new_delta.retain(1, attribute.clone().into());
                    break;
                },
            }
        }

        Some(new_delta)
    }
}
