use crate::{
    client::{extensions::InsertExt, util::is_newline},
    core::{Delta, DeltaIter},
};

pub struct AutoExitBlockExt {}

impl InsertExt for AutoExitBlockExt {
    fn ext_name(&self) -> &str { "AutoExitBlockExt" }

    fn apply(&self, delta: &Delta, _replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        // Auto exit block will be triggered by enter two new lines
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let _prev = iter.next_op_before(index);
        let _next = iter.next_op();

        None
    }
}
