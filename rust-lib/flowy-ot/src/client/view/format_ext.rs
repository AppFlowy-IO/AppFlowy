use crate::{
    client::view::FormatExt,
    core::{Attribute, AttributeScope, Attributes, Delta, DeltaBuilder, DeltaIter, Interval},
};

pub struct FormatLinkAtCaretPositionExt {}

impl FormatExt for FormatLinkAtCaretPositionExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        let mut iter = DeltaIter::new(delta);
        iter.seek(interval.start);
        let (before, after) = (iter.next(), iter.next());
        let mut start = interval.start;
        let mut retain = 0;

        if let Some(before) = before {
            if before.contain_attribute(attribute) {
                start -= before.length();
                retain += before.length();
            }
        }

        if let Some(after) = after {
            if after.contain_attribute(attribute) {
                if retain != 0 {
                    retain += after.length();
                }
            }
        }

        if retain == 0 {
            return None;
        }

        Some(
            DeltaBuilder::new()
                .retain(start, Attributes::default())
                .retain(retain, (attribute.clone()).into())
                .build(),
        )
    }
}

pub struct ResolveLineFormatExt {}

impl FormatExt for ResolveLineFormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Block {
            return None;
        }

        let mut new_delta = Delta::new();
        new_delta.retain(interval.start, Attributes::default());

        let mut iter = DeltaIter::new(delta);
        iter.seek(interval.start);

        None
    }
}

pub struct ResolveInlineFormatExt {}

impl FormatExt for ResolveInlineFormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        unimplemented!()
    }
}
