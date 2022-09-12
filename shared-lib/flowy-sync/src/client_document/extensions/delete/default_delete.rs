use crate::client_document::DeleteExt;
use lib_ot::{
    core::{Interval, OperationBuilder},
    text_delta::TextDelta,
};

pub struct DefaultDelete {}
impl DeleteExt for DefaultDelete {
    fn ext_name(&self) -> &str {
        "DefaultDelete"
    }

    fn apply(&self, _delta: &TextDelta, interval: Interval) -> Option<TextDelta> {
        Some(
            OperationBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
