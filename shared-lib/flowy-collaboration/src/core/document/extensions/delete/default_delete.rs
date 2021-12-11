use crate::core::document::DeleteExt;
use lib_ot::{
    core::{DeltaBuilder, Interval},
    rich_text::RichTextDelta,
};

pub struct DefaultDelete {}
impl DeleteExt for DefaultDelete {
    fn ext_name(&self) -> &str { "DefaultDelete" }

    fn apply(&self, _delta: &RichTextDelta, interval: Interval) -> Option<RichTextDelta> {
        Some(
            DeltaBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
