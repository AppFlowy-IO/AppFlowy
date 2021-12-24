mod delta;
mod flowy_str;
mod interval;
mod operation;

use crate::errors::OTError;
pub use delta::*;
pub use flowy_str::*;
pub use interval::*;
pub use operation::*;

pub trait OperationTransformable {
    /// Merges the operation with `other` into one operation while preserving
    /// the changes of both.
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized;
    /// Transforms two operations a and b that happened concurrently and
    /// produces two operations a' and b'.
    ///  (a', b') = a.transform(b)
    ///  a.compose(b') = b.compose(a')
    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized;
    /// Inverts the operation with `other` to produces undo operation.
    /// undo = a.invert(b)
    /// new_b = b.compose(a)
    /// b = new_b.compose(undo)
    fn invert(&self, other: &Self) -> Self;
}
