use crate::core::{Delta, DeltaBuilder};
use crate::rich_text::TextAttributes;

pub type RichTextDelta = Delta<TextAttributes>;
pub type RichTextDeltaBuilder = DeltaBuilder<TextAttributes>;
