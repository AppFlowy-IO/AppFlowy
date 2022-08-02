use crate::core::delta::{trim, Delta};
use crate::core::operation::Attributes;
use crate::core::Operation;

/// A builder for creating new [Delta] objects.
///
/// Note that all edit operations must be sorted; the start point of each
/// interval must be no less than the end point of the previous one.
///
/// # Examples
///
/// ```
/// use lib_ot::core::TextDeltaBuilder;
/// let delta = TextDeltaBuilder::new()
///         .insert("AppFlowy")
///         .build();
/// assert_eq!(delta.content_str().unwrap(), "AppFlowy");
/// ```
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

    pub fn from_operations(operations: Vec<Operation<T>>) -> Delta<T> {
        let mut delta = DeltaBuilder::default().build();
        operations.into_iter().for_each(|operation| {
            delta.add(operation);
        });
        delta
    }

    /// Retain the 'n' characters with the attributes. Use 'retain' instead if you don't
    /// need any attributes.
    /// # Examples
    ///
    /// ```
    /// use lib_ot::rich_text::{RichTextAttribute, RichTextDelta, RichTextDeltaBuilder};
    ///
    /// let mut attribute = RichTextAttribute::Bold(true);
    /// let delta = RichTextDeltaBuilder::new().retain_with_attributes(7, attribute.into()).build();
    ///
    /// assert_eq!(delta.to_json_str(), r#"[{"retain":7,"attributes":{"bold":true}}]"#);
    /// ```
    pub fn retain_with_attributes(mut self, n: usize, attrs: T) -> Self {
        self.delta.retain(n, attrs);
        self
    }

    pub fn retain(mut self, n: usize) -> Self {
        self.delta.retain(n, T::default());
        self
    }

    /// Deletes the given interval. Panics if interval is not properly sorted.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{OperationTransform, TextDeltaBuilder};
    ///
    /// let delta = TextDeltaBuilder::new()
    ///         .insert("AppFlowy...")
    ///         .build();
    ///
    /// let changeset = TextDeltaBuilder::new()
    ///         .retain(8)
    ///         .delete(3)
    ///         .build();
    ///
    /// let new_delta = delta.compose(&changeset).unwrap();
    /// assert_eq!(new_delta.content_str().unwrap(), "AppFlowy");
    /// ```
    pub fn delete(mut self, n: usize) -> Self {
        self.delta.delete(n);
        self
    }

    /// Inserts the string with attributes. Use 'insert' instead if you don't
    /// need any attributes.
    pub fn insert_with_attributes(mut self, s: &str, attrs: T) -> Self {
        self.delta.insert(s, attrs);
        self
    }

    pub fn insert(mut self, s: &str) -> Self {
        self.delta.insert(s, T::default());
        self
    }

    /// Removes trailing retain operation with empty attributes
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{OperationTransform, TextDeltaBuilder};
    /// use lib_ot::rich_text::{RichTextAttribute, RichTextDeltaBuilder};
    /// let delta = TextDeltaBuilder::new()
    ///         .retain(3)
    ///         .trim()
    ///         .build();
    /// assert_eq!(delta.ops.len(), 0);
    ///
    /// let delta = RichTextDeltaBuilder::new()
    ///         .retain_with_attributes(3, RichTextAttribute::Bold(true).into())
    ///         .trim()
    ///         .build();
    /// assert_eq!(delta.ops.len(), 1);
    /// ```
    pub fn trim(mut self) -> Self {
        trim(&mut self.delta);
        self
    }

    /// Builds the `Delta`
    pub fn build(self) -> Delta<T> {
        self.delta
    }
}
