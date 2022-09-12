use crate::core::{OperationBuilder, Operations};
use crate::text_delta::TextAttributes;

pub type TextDelta = Operations<TextAttributes>;
pub type TextDeltaBuilder = OperationBuilder<TextAttributes>;
