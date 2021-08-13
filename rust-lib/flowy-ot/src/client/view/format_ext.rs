use crate::{
    client::view::{FormatExt, NEW_LINE},
    core::{
        Attribute,
        AttributeScope,
        Attributes,
        CharMetric,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Interval,
        Operation,
    },
};

pub struct FormatLinkAtCaretPositionExt {}

impl FormatExt for FormatLinkAtCaretPositionExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);
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
        iter.seek::<CharMetric>(interval.start);

        None
    }
}

pub struct ResolveInlineFormatExt {}

impl FormatExt for ResolveInlineFormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Inline {
            return None;
        }
        let mut new_delta = DeltaBuilder::new()
            .retain(interval.start, Attributes::default())
            .build();

        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);

        let mut cur = 0;
        let len = interval.size();

        while cur < len && iter.has_next() {
            let some_op = iter.next_op_with_len(len - cur);
            if some_op.is_none() {
                return Some(new_delta);
            }
            let op = some_op.unwrap();
            if let Operation::Insert(insert) = &op {
                let mut s = insert.s.as_str();
                match s.find(NEW_LINE) {
                    None => {
                        new_delta.retain(op.length(), attribute.clone().into());
                    },
                    Some(mut line_break) => {
                        let mut pos = 0;
                        let mut some_line_break = Some(line_break);
                        while some_line_break.is_some() {
                            let line_break = some_line_break.unwrap();
                            new_delta.retain(line_break - pos, attribute.clone().into());
                            new_delta.retain(1, Attributes::default());
                            pos = line_break + 1;

                            s = &s[pos..s.len()];
                            some_line_break = s.find(NEW_LINE);
                        }

                        if pos < op.length() {
                            new_delta.retain(op.length() - pos, attribute.clone().into());
                        }
                    },
                }
            }

            cur += op.length();
        }

        Some(new_delta)
    }
}
