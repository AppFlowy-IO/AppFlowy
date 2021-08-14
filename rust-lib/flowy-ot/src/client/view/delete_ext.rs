use crate::{
    client::view::DeleteExt,
    core::{Attributes, Delta, DeltaBuilder, Interval},
};

pub struct DefaultDeleteExt {}
impl DeleteExt for DefaultDeleteExt {
    fn apply(&self, _delta: &Delta, interval: Interval) -> Option<Delta> {
        Some(
            DeltaBuilder::new()
                .retain(interval.start, Attributes::empty())
                .delete(interval.size())
                .build(),
        )
    }
}
