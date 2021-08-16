use crate::{
    client::{extensions::InsertExt, util::is_whitespace},
    core::{CharMetric, Delta, DeltaIter},
};

pub struct AutoFormatExt {}
impl InsertExt for AutoFormatExt {
    fn ext_name(&self) -> &str { "AutoFormatExt" }

    fn apply(&self, delta: &Delta, _replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        // enter whitespace to trigger auto format
        if !is_whitespace(text) {
            return None;
        }
        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(index);
        let prev = iter.next_op();
        if prev.is_none() {
            return None;
        }

        let _prev = prev.unwrap();

        None
    }
}
