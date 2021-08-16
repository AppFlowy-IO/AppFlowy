use crate::{
    client::extensions::FormatExt,
    core::{Attribute, AttributeKey, CharMetric, Delta, DeltaBuilder, DeltaIter, Interval},
};

pub struct FormatLinkAtCaretPositionExt {}

impl FormatExt for FormatLinkAtCaretPositionExt {
    fn ext_name(&self) -> &str { "FormatLinkAtCaretPositionExt" }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.key != AttributeKey::Link || interval.size() != 0 {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);

        let (before, after) = (iter.next_op_before(interval.size()), iter.next());
        let mut start = interval.end;
        let mut retain = 0;

        if let Some(before) = before {
            if before.contain_attribute(attribute) {
                start -= before.len();
                retain += before.len();
            }
        }

        if let Some(after) = after {
            if after.contain_attribute(attribute) {
                if retain != 0 {
                    retain += after.len();
                }
            }
        }

        if retain == 0 {
            return None;
        }

        Some(
            DeltaBuilder::new()
                .retain(start)
                .retain_with_attributes(retain, (attribute.clone()).into())
                .build(),
        )
    }
}
