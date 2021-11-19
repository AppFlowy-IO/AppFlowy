use crate::{core::extensions::InsertExt, util::is_newline};
use flowy_ot::core::{
    attributes_except_header,
    plain_attributes,
    Attribute,
    AttributeKey,
    Attributes,
    Delta,
    DeltaBuilder,
    DeltaIter,
    NEW_LINE,
};

pub struct PreserveBlockFormatOnInsert {}
impl InsertExt for PreserveBlockFormatOnInsert {
    fn ext_name(&self) -> &str { std::any::type_name::<PreserveBlockFormatOnInsert>() }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::from_offset(delta, index);
        match iter.next_op_with_newline() {
            None => {},
            Some((newline_op, offset)) => {
                let newline_attributes = newline_op.get_attributes();
                let block_attributes = attributes_except_header(&newline_op);
                if block_attributes.is_empty() {
                    return None;
                }

                let mut reset_attribute = Attributes::new();
                if newline_attributes.contains_key(&AttributeKey::Header) {
                    reset_attribute.add(Attribute::Header(1));
                }

                let lines: Vec<_> = text.split(NEW_LINE).collect();
                let mut new_delta = DeltaBuilder::new().retain(index + replace_len).build();
                lines.iter().enumerate().for_each(|(i, line)| {
                    if !line.is_empty() {
                        new_delta.insert(line, plain_attributes());
                    }

                    if i == 0 {
                        new_delta.insert(NEW_LINE, newline_attributes.clone());
                    } else if i < lines.len() - 1 {
                        new_delta.insert(NEW_LINE, block_attributes.clone());
                    } else {
                        // do nothing
                    }
                });
                if !reset_attribute.is_empty() {
                    new_delta.retain(offset, plain_attributes());
                    let len = newline_op.get_data().find(NEW_LINE).unwrap();
                    new_delta.retain(len, plain_attributes());
                    new_delta.retain(1, reset_attribute.clone());
                }

                return Some(new_delta);
            },
        }

        None
    }
}
