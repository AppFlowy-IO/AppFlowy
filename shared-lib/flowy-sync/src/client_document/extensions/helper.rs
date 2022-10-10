use crate::util::find_newline;
use lib_ot::core::AttributeEntry;
use lib_ot::text_delta::{empty_attributes, AttributeScope, TextOperation, TextOperations};

pub(crate) fn line_break(op: &TextOperation, attribute: &AttributeEntry, scope: AttributeScope) -> TextOperations {
    let mut new_delta = TextOperations::new();
    let mut start = 0;
    let end = op.len();
    let mut s = op.get_data();

    while let Some(line_break) = find_newline(s) {
        match scope {
            AttributeScope::Inline => {
                new_delta.retain(line_break - start, attribute.clone().into());
                new_delta.retain(1, empty_attributes());
            }
            AttributeScope::Block => {
                new_delta.retain(line_break - start, empty_attributes());
                new_delta.retain(1, attribute.clone().into());
            }
            _ => {
                log::error!("Unsupported parser line break for {:?}", scope);
            }
        }

        start = line_break + 1;
        s = &s[start..s.len()];
    }

    if start < end {
        match scope {
            AttributeScope::Inline => new_delta.retain(end - start, attribute.clone().into()),
            AttributeScope::Block => new_delta.retain(end - start, empty_attributes()),
            _ => log::error!("Unsupported parser line break for {:?}", scope),
        }
    }
    new_delta
}
