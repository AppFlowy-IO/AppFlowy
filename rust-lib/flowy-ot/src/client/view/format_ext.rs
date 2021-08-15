use crate::{
    client::view::{util::find_newline, FormatExt, NEW_LINE},
    core::{
        Attribute,
        AttributeKey,
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
    fn ext_name(&self) -> &str { "FormatLinkAtCaretPositionExt" }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.key != AttributeKey::Link || interval.size() != 0 {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);

        let (before, after) = (iter.next_op_with_len(interval.size()), iter.next());
        let mut start = interval.end;
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
                .retain(start)
                .retain_with_attributes(retain, (attribute.clone()).into())
                .build(),
        )
    }
}

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
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.length(), Attributes::empty()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Block);
                    new_delta.extend(tmp_delta);
                },
            }

            start += next_op.length();
        }

        while iter.has_next() {
            let op = iter
                .next_op()
                .expect("Unexpected None, iter.has_next() must return op");

            match find_newline(op.get_data()) {
                None => new_delta.retain(op.length(), Attributes::empty()),
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

pub struct ResolveInlineFormatExt {}
impl FormatExt for ResolveInlineFormatExt {
    fn ext_name(&self) -> &str { "ResolveInlineFormatExt" }

    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        if attribute.scope != AttributeScope::Inline {
            return None;
        }
        let mut new_delta = DeltaBuilder::new().retain(interval.start).build();
        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(interval.start);

        let mut start = 0;
        let end = interval.size();

        while start < end && iter.has_next() {
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.length(), attribute.clone().into()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Inline);
                    new_delta.extend(tmp_delta);
                },
            }

            start += next_op.length();
        }

        Some(new_delta)
    }
}

fn line_break(op: &Operation, attribute: &Attribute, scope: AttributeScope) -> Delta {
    let mut new_delta = Delta::new();
    let mut start = 0;
    let end = op.length();
    let mut s = op.get_data();

    while let Some(line_break) = find_newline(s) {
        match scope {
            AttributeScope::Inline => {
                new_delta.retain(line_break - start, attribute.clone().into());
                new_delta.retain(1, Attributes::empty());
            },
            AttributeScope::Block => {
                new_delta.retain(line_break - start, Attributes::empty());
                new_delta.retain(1, attribute.clone().into());
            },
            _ => {
                log::error!("Unsupported parser line break for {:?}", scope);
            },
        }

        start = line_break + 1;
        s = &s[start..s.len()];
    }

    if start < end {
        match scope {
            AttributeScope::Inline => new_delta.retain(end - start, attribute.clone().into()),
            AttributeScope::Block => new_delta.retain(end - start, Attributes::empty()),
            _ => log::error!("Unsupported parser line break for {:?}", scope),
        }
    }
    new_delta
}
