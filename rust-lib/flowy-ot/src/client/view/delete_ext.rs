use crate::{
    client::view::DeleteExt,
    core::{Delta, DeltaBuilder, Interval},
};

pub struct DefaultDeleteExt {}
impl DeleteExt for DefaultDeleteExt {
    fn apply(&self, _delta: &Delta, interval: Interval) -> Option<Delta> {
        Some(
            DeltaBuilder::new()
                .retain(interval.start)
                .delete(interval.size())
                .build(),
        )
    }
}
