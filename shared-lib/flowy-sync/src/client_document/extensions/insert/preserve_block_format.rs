use crate::{client_document::InsertExt, util::is_newline};
use lib_ot::core::AttributeHashMap;
use lib_ot::{
    core::{DeltaOperationBuilder, OperationIterator, NEW_LINE},
    text_delta::{attributes_except_header, empty_attributes, BuildInTextAttributeKey, DeltaTextOperations},
};

pub struct PreserveBlockFormatOnInsert {}
impl InsertExt for PreserveBlockFormatOnInsert {
    fn ext_name(&self) -> &str {
        "PreserveBlockFormatOnInsert"
    }

    fn apply(
        &self,
        delta: &DeltaTextOperations,
        replace_len: usize,
        text: &str,
        index: usize,
    ) -> Option<DeltaTextOperations> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = OperationIterator::from_offset(delta, index);
        match iter.next_op_with_newline() {
            None => {}
            Some((newline_op, offset)) => {
                let newline_attributes = newline_op.get_attributes();
                let block_attributes = attributes_except_header(&newline_op);
                if block_attributes.is_empty() {
                    return None;
                }

                let mut reset_attribute = AttributeHashMap::new();
                if newline_attributes.contains_key(BuildInTextAttributeKey::Header.as_ref()) {
                    reset_attribute.insert(BuildInTextAttributeKey::Header, 1);
                }

                let lines: Vec<_> = text.split(NEW_LINE).collect();
                let mut new_delta = DeltaOperationBuilder::new().retain(index + replace_len).build();
                lines.iter().enumerate().for_each(|(i, line)| {
                    if !line.is_empty() {
                        new_delta.insert(line, empty_attributes());
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
                    new_delta.retain(offset, empty_attributes());
                    let len = newline_op.get_data().find(NEW_LINE).unwrap();
                    new_delta.retain(len, empty_attributes());
                    new_delta.retain(1, reset_attribute);
                }

                return Some(new_delta);
            }
        }

        None
    }
}
