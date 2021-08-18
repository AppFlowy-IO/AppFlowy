use crate::{
    client::extensions::DeleteExt,
    core::{Delta, DeltaBuilder, Interval},
};

pub struct DefaultDelete {}
impl DeleteExt for DefaultDelete {
    fn ext_name(&self) -> &str { "DefaultDelete" }

    fn apply(&self, _delta: &Delta, interval: Interval) -> Option<Delta> {
        Some(
            DeltaBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
