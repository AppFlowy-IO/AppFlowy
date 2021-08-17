use crate::{
    client::{extensions::InsertExt, util::is_newline},
    core::{
        attributes_except_header,
        AttributeBuilder,
        AttributeKey,
        Attributes,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Operation,
        NEW_LINE,
    },
};

pub struct PreserveBlockStyleOnInsertExt {}
impl InsertExt for PreserveBlockStyleOnInsertExt {
    fn ext_name(&self) -> &str { "PreserveBlockStyleOnInsertExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::from_offset(delta, index);
        match iter.first_newline_op() {
            None => {},
            Some((newline_op, offset)) => {
                let newline_attributes = newline_op.get_attributes();
                let block_attributes = attributes_except_header(&newline_op);
                if block_attributes.is_empty() {
                    return None;
                }

                let mut reset_attribute = Attributes::new();
                if newline_attributes.contains_key(&AttributeKey::Header) {
                    reset_attribute.add(AttributeKey::Header.value(""));
                }

                let lines: Vec<_> = text.split(NEW_LINE).collect();
                let line_count = lines.len();
                let mut new_delta = DeltaBuilder::new().retain(index + replace_len).build();
                lines.iter().enumerate().for_each(|(i, line)| {
                    if !line.is_empty() {
                        new_delta.insert(line, Attributes::empty());
                    }

                    if i == 0 {
                        new_delta.insert(NEW_LINE, newline_attributes.clone());
                    } else if i < lines.len() - 1 {
                        new_delta.insert(NEW_LINE, block_attributes.clone());
                    } else {
                        // do nothing
                    }

                    log::info!("{}", new_delta);
                });
                if !reset_attribute.is_empty() {
                    new_delta.retain(offset, Attributes::empty());
                    let len = newline_op.get_data().find(NEW_LINE).unwrap();
                    new_delta.retain(len, Attributes::empty());
                    new_delta.retain(1, reset_attribute.clone());
                }

                return Some(new_delta);
            },
        }

        None
    }
}
