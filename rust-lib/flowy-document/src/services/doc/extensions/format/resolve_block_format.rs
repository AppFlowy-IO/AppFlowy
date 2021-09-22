use crate::services::doc::{
    extensions::{format::helper::line_break, FormatExt},
    util::find_newline,
};
use flowy_ot::core::{plain_attributes, Attribute, AttributeScope, Delta, DeltaBuilder, DeltaIter, Interval};

pub struct ResolveBlockFormat {}
impl FormatExt for ResolveBlockFormat {
    fn ext_name(&self) -> &str { std::any::type_name::<ResolveBlockFormat>() }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Block {
            return None;
        }

        let mut new_delta = DeltaBuilder::new().retain(interval.start).build();
        let mut iter = DeltaIter::from_offset(delta, interval.start);
        let mut start = 0;
        let end = interval.size();
        while start < end && iter.has_next() {
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.len(), plain_attributes()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Block);
                    new_delta.extend(tmp_delta);
                },
            }

            start += next_op.len();
        }

        while iter.has_next() {
            let op = iter.next_op().expect("Unexpected None, iter.has_next() must return op");

            match find_newline(op.get_data()) {
                None => new_delta.retain(op.len(), plain_attributes()),
                Some(line_break) => {
                    new_delta.retain(line_break, plain_attributes());
                    new_delta.retain(1, attribute.clone().into());
                    break;
                },
            }
        }

        Some(new_delta)
    }
}
