use crate::services::doc::util::find_newline;
use flowy_ot::core::{plain_attributes, Attribute, AttributeScope, Delta, Operation};

pub(crate) fn line_break(op: &Operation, attribute: &Attribute, scope: AttributeScope) -> Delta {
    let mut new_delta = Delta::new();
    let mut start = 0;
    let end = op.len();
    let mut s = op.get_data();

    while let Some(line_break) = find_newline(s) {
        match scope {
            AttributeScope::Inline => {
                new_delta.retain(line_break - start, attribute.clone().into());
                new_delta.retain(1, plain_attributes());
            },
            AttributeScope::Block => {
                new_delta.retain(line_break - start, plain_attributes());
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
            AttributeScope::Block => new_delta.retain(end - start, plain_attributes()),
            _ => log::error!("Unsupported parser line break for {:?}", scope),
        }
    }
    new_delta
}
