use crate::document::InsertExt;
pub use auto_exit_block::*;
pub use auto_format::*;
pub use default_insert::*;
use lib_ot::rich_text::RichTextDelta;
pub use preserve_block_format::*;
pub use preserve_inline_format::*;
pub use reset_format_on_new_line::*;

mod auto_exit_block;
mod auto_format;
mod default_insert;
mod preserve_block_format;
mod preserve_inline_format;
mod reset_format_on_new_line;

pub struct InsertEmbedsExt {}
impl InsertExt for InsertEmbedsExt {
    fn ext_name(&self) -> &str { "InsertEmbedsExt" }

    fn apply(&self, _delta: &RichTextDelta, _replace_len: usize, _text: &str, _index: usize) -> Option<RichTextDelta> {
        None
    }
}

pub struct ForceNewlineForInsertsAroundEmbedExt {}
impl InsertExt for ForceNewlineForInsertsAroundEmbedExt {
    fn ext_name(&self) -> &str { "ForceNewlineForInsertsAroundEmbedExt" }

    fn apply(&self, _delta: &RichTextDelta, _replace_len: usize, _text: &str, _index: usize) -> Option<RichTextDelta> {
        None
    }
}
