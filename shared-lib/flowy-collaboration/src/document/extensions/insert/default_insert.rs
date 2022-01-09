use crate::document::InsertExt;
use lib_ot::{
    core::{Attributes, DeltaBuilder, DeltaIter, NEW_LINE},
    rich_text::{RichTextAttributeKey, RichTextAttributes, RichTextDelta},
};

pub struct DefaultInsertAttribute {}
impl InsertExt for DefaultInsertAttribute {
    fn ext_name(&self) -> &str { "DefaultInsertAttribute" }

    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta> {
        let iter = DeltaIter::new(delta);
        let mut attributes = RichTextAttributes::new();

        // Enable each line split by "\n" remains the block attributes. for example:
        // insert "\n" to "123456" at index 3
        //
        // [{"insert":"123"},{"insert":"\n","attributes":{"header":1}},
        // {"insert":"456"},{"insert":"\n","attributes":{"header":1}}]
        if text.ends_with(NEW_LINE) {
            match iter.last() {
                None => {},
                Some(op) => {
                    if op.get_attributes().contains_key(&RichTextAttributeKey::Header) {
                        attributes.extend_other(op.get_attributes());
                    }
                },
            }
        }

        Some(
            DeltaBuilder::new()
                .retain(index + replace_len)
                .insert_with_attributes(text, attributes)
                .build(),
        )
    }
}
