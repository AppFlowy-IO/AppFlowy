use crate::{
    client::view::FormatExt,
    core::{Attribute, Delta, Interval},
};

pub struct FormatLinkAtCaretPositionExt {}

impl FormatExt for FormatLinkAtCaretPositionExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        unimplemented!()
    }
}

pub struct ResolveLineFormatExt {}

impl FormatExt for ResolveLineFormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        unimplemented!()
    }
}

pub struct ResolveInlineFormatExt {}

impl FormatExt for ResolveInlineFormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta> {
        unimplemented!()
    }
}
