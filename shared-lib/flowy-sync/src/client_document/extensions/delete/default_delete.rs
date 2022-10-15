use crate::client_document::DeleteExt;
use lib_ot::{
    core::{Interval, OperationBuilder},
    text_delta::TextOperations,
};

pub struct DefaultDelete {}
impl DeleteExt for DefaultDelete {
    fn ext_name(&self) -> &str {
        "DefaultDelete"
    }

    fn apply(&self, _delta: &TextOperations, interval: Interval) -> Option<TextOperations> {
        Some(
            OperationBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
