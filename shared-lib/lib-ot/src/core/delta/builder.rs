use crate::core::delta::operation::OperationAttributes;
use crate::core::delta::{trim, DeltaOperations};

/// A builder for creating new [Operations] objects.
///
/// Note that all edit operations must be sorted; the start point of each
/// interval must be no less than the end point of the previous one.
///
/// # Examples
///
/// ```
/// use lib_ot::core::DeltaBuilder;
/// let delta = DeltaBuilder::new()
///         .insert("AppFlowy")
///         .build();
/// assert_eq!(delta.content().unwrap(), "AppFlowy");
/// ```
pub struct DeltaOperationBuilder<T: OperationAttributes> {
    delta: DeltaOperations<T>,
}

impl<T> std::default::Default for DeltaOperationBuilder<T>
where
    T: OperationAttributes,
{
    fn default() -> Self {
        Self {
            delta: DeltaOperations::new(),
        }
    }
}

impl<T> DeltaOperationBuilder<T>
where
    T: OperationAttributes,
{
    pub fn new() -> Self {
        DeltaOperationBuilder::default()
    }

    pub fn from_delta_operation(delta_operation: DeltaOperations<T>) -> Self {
        debug_assert!(delta_operation.utf16_base_len == 0);
        let mut builder = DeltaOperationBuilder::new();
        delta_operation.ops.into_iter().for_each(|operation| {
            builder.delta.add(operation);
        });
        builder
    }

    /// Retain the 'n' characters with the attributes. Use 'retain' instead if you don't
    /// need any attributes.
    /// # Examples
    ///
    /// ```
    /// use lib_ot::text_delta::{BuildInTextAttribute, DeltaTextOperations, DeltaTextOperationBuilder};
    ///
    /// let mut attribute = BuildInTextAttribute::Bold(true);
    /// let delta = DeltaTextOperationBuilder::new().retain_with_attributes(7, attribute.into()).build();
    ///
    /// assert_eq!(delta.json_str(), r#"[{"retain":7,"attributes":{"bold":true}}]"#);
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
    /// use lib_ot::core::{OperationTransform, DeltaBuilder};
    ///
    /// let delta = DeltaBuilder::new()
    ///         .insert("AppFlowy...")
    ///         .build();
    ///
    /// let changeset = DeltaBuilder::new()
    ///         .retain(8)
    ///         .delete(3)
    ///         .build();
    ///
    /// let new_delta = delta.compose(&changeset).unwrap();
    /// assert_eq!(new_delta.content().unwrap(), "AppFlowy");
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
    /// use lib_ot::core::{OperationTransform, DeltaBuilder};
    /// use lib_ot::text_delta::{BuildInTextAttribute, DeltaTextOperationBuilder};
    /// let delta = DeltaBuilder::new()
    ///         .retain(3)
    ///         .trim()
    ///         .build();
    /// assert_eq!(delta.ops.len(), 0);
    ///
    /// let delta = DeltaTextOperationBuilder::new()
    ///         .retain_with_attributes(3, BuildInTextAttribute::Bold(true).into())
    ///         .trim()
    ///         .build();
    /// assert_eq!(delta.ops.len(), 1);
    /// ```
    pub fn trim(mut self) -> Self {
        trim(&mut self.delta);
        self
    }

    /// Builds the `Delta`
    pub fn build(self) -> DeltaOperations<T> {
        self.delta
    }
}
