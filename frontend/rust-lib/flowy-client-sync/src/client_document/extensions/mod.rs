pub use delete::*;
pub use format::*;
pub use insert::*;
use lib_ot::core::AttributeEntry;
use lib_ot::{core::Interval, text_delta::DeltaTextOperations};

mod delete;
mod format;
mod helper;
mod insert;

pub type InsertExtension = Box<dyn InsertExt + Send + Sync>;
pub type FormatExtension = Box<dyn FormatExt + Send + Sync>;
pub type DeleteExtension = Box<dyn DeleteExt + Send + Sync>;

pub trait InsertExt {
    fn ext_name(&self) -> &str;
    fn apply(
        &self,
        delta: &DeltaTextOperations,
        replace_len: usize,
        text: &str,
        index: usize,
    ) -> Option<DeltaTextOperations>;
}

pub trait FormatExt {
    fn ext_name(&self) -> &str;
    fn apply(
        &self,
        delta: &DeltaTextOperations,
        interval: Interval,
        attribute: &AttributeEntry,
    ) -> Option<DeltaTextOperations>;
}

pub trait DeleteExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &DeltaTextOperations, interval: Interval) -> Option<DeltaTextOperations>;
}
