use crate::client_document::InsertExt;
use lib_ot::core::AttributeHashMap;
use lib_ot::{
    core::{OperationAttributes, OperationBuilder, OperationIterator, NEW_LINE},
    text_delta::{BuildInTextAttributeKey, TextOperations},
};

pub struct DefaultInsertAttribute {}
impl InsertExt for DefaultInsertAttribute {
    fn ext_name(&self) -> &str {
        "DefaultInsertAttribute"
    }

    fn apply(&self, delta: &TextOperations, replace_len: usize, text: &str, index: usize) -> Option<TextOperations> {
        let iter = OperationIterator::new(delta);
        let mut attributes = AttributeHashMap::new();

        // Enable each line split by "\n" remains the block attributes. for example:
        // insert "\n" to "123456" at index 3
        //
        // [{"insert":"123"},{"insert":"\n","attributes":{"header":1}},
        // {"insert":"456"},{"insert":"\n","attributes":{"header":1}}]
        if text.ends_with(NEW_LINE) {
            match iter.last() {
                None => {}
                Some(op) => {
                    if op
                        .get_attributes()
                        .contains_key(BuildInTextAttributeKey::Header.as_ref())
                    {
                        attributes.extend(op.get_attributes());
                    }
                }
            }
        }

        Some(
            OperationBuilder::new()
                .retain(index + replace_len)
                .insert_with_attributes(text, attributes)
                .build(),
        )
    }
}
