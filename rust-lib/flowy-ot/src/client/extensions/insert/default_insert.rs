use crate::{
    client::extensions::InsertExt,
    core::{AttributeKey, Attributes, Delta, DeltaBuilder, DeltaIter, NEW_LINE},
};

pub struct DefaultInsertExt {}
impl InsertExt for DefaultInsertExt {
    fn ext_name(&self) -> &str { "DefaultInsertExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        let iter = DeltaIter::new(delta);
        let mut attributes = Attributes::new();

        // Enable each line split by "\n" remains the block attributes. for example:
        // insert "\n" to "123456" at index 3
        //
        // [{"insert":"123"},{"insert":"\n","attributes":{"header":"1"}},
        // {"insert":"456"},{"insert":"\n","attributes":{"header":"1"}}]
        if text.ends_with(NEW_LINE) {
            match iter.last() {
                None => {},
                Some(op) => {
                    if op.get_attributes().contains_key(&AttributeKey::Header) {
                        attributes.extend(op.get_attributes());
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
