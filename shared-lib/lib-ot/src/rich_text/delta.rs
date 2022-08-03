use crate::core::{Delta, DeltaBuilder};
use crate::rich_text::RichTextAttributes;

pub type RichTextDelta = Delta<RichTextAttributes>;
pub type RichTextDeltaBuilder = DeltaBuilder<RichTextAttributes>;
