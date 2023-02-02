use crate::client_document::DeleteExt;
use lib_ot::{
    core::{DeltaOperationBuilder, Interval},
    text_delta::DeltaTextOperations,
};

pub struct DefaultDelete {}
impl DeleteExt for DefaultDelete {
    fn ext_name(&self) -> &str {
        "DefaultDelete"
    }

    fn apply(&self, _delta: &DeltaTextOperations, interval: Interval) -> Option<DeltaTextOperations> {
        Some(
            DeltaOperationBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
