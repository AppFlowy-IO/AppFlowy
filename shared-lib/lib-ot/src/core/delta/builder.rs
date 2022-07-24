use crate::core::delta::{trim, Delta};
use crate::core::operation::{Attributes, PhantomAttributes};

pub type PlainTextDeltaBuilder = DeltaBuilder<PhantomAttributes>;

/// A builder for creating new [Delta] objects.
///
/// Note that all edit operations must be sorted; the start point of each
/// interval must be no less than the end point of the previous one.
pub struct DeltaBuilder<T: Attributes> {
    delta: Delta<T>,
}

impl<T> std::default::Default for DeltaBuilder<T>
where
    T: Attributes,
{
    fn default() -> Self {
        Self { delta: Delta::new() }
    }
}

impl<T> DeltaBuilder<T>
where
    T: Attributes,
{
    pub fn new() -> Self {
        DeltaBuilder::default()
    }

    /// Retain the 'n' characters with the attributes. Use 'retain' instead if you don't
    /// need any attributes.
    pub fn retain_with_attributes(mut self, n: usize, attrs: T) -> Self {
        self.delta.retain(n, attrs);
        self
    }

    pub fn retain(mut self, n: usize) -> Self {
        self.delta.retain(n, T::default());
        self
    }

    /// Deletes the given interval. Panics if interval is not properly sorted.
    pub fn delete(mut self, n: usize) -> Self {
        self.delta.delete(n);
        self
    }

    /// Insert the string with attributes. Use 'insert' instead if you don't
    /// need any attributes.
    pub fn insert_with_attributes(mut self, s: &str, attrs: T) -> Self {
        self.delta.insert(s, attrs);
        self
    }

    pub fn insert(mut self, s: &str) -> Self {
        self.delta.insert(s, T::default());
        self
    }

    pub fn trim(mut self) -> Self {
        trim(&mut self.delta);
        self
    }

    /// Builds the `Delta`
    pub fn build(self) -> Delta<T> {
        self.delta
    }
}
