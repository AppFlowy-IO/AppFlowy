use crate::core::interval::Interval;
use crate::core::ot_str::OTString;
use crate::errors::OTError;
use serde::{Deserialize, Serialize, __private::Formatter};
use std::fmt::Display;
use std::{
    cmp::min,
    fmt,
    fmt::Debug,
    ops::{Deref, DerefMut},
};

pub trait OperationTransform {
    /// Merges the operation with `other` into one operation while preserving
    /// the changes of both.    
    ///
    /// # Arguments
    ///
    /// * `other`: The delta gonna to merge.
    ///
    /// # Examples
    ///
    /// ```
    ///  use lib_ot::core::{OperationTransform, DeltaBuilder};
    ///  let delta = DeltaBuilder::new().build();
    ///  let other = DeltaBuilder::new().insert("abc").build();
    ///  let new_document = delta.compose(&other).unwrap();
    ///  assert_eq!(new_document.content().unwrap(), "abc".to_owned());
    /// ```
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized;

    /// Transforms two operations a and b that happened concurrently and
    /// produces two operations a' and b'.
    ///  (a', b') = a.transform(b)
    ///  a.compose(b') = b.compose(a')    
    ///
    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized;

    /// Returns the invert delta from the other. It can be used to do the undo operation.
    ///
    /// # Arguments
    ///
    /// * `other`:  Generate the undo delta for [Other]. [Other] can compose the undo delta to return
    /// to the previous state.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{OperationTransform, DeltaBuilder};
    /// let initial_delta = DeltaBuilder::new().build();
    /// let delta = DeltaBuilder::new().insert("abc").build();
    ///
    /// let undo_delta = delta.invert(&initial_delta);
    /// let composed_delta = initial_delta.compose(&delta).unwrap();
    /// let inverted_delta = composed_delta.compose(&undo_delta).unwrap();
    ///
    /// assert_eq!(initial_delta, inverted_delta);
    ///
    /// ```
    fn invert(&self, other: &Self) -> Self;
}

/// Each operation can carry attributes. For example, the [TextAttributes] has a list of key/value attributes.
/// Such as { bold: true, italic: true }.  
///
///Because [Operation] is generic over the T, so you must specify the T. For example, the [Delta] uses
///[EmptyAttributes] as the T. [EmptyAttributes] does nothing, just a phantom.
///
pub trait OperationAttributes: Default + Display + Eq + PartialEq + Clone + Debug + OperationTransform {
    fn is_empty(&self) -> bool {
        true
    }

    /// Remove the attribute which value is None.
    fn remove(&mut self) {}

    fn extend(&mut self, _other: Self) {}
}

/// [DeltaOperation] consists of three types.
/// * Delete
/// * Retain
/// * Insert
///
/// You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/delta) out for more information.
///
/// The [T] should support serde if you want to serialize/deserialize the operation
/// to json string. You could check out the operation_serde.rs for more information.
///
#[derive(Debug, Clone, Eq, PartialEq)]
pub enum DeltaOperation<T: OperationAttributes> {
    Delete(usize),
    Retain(Retain<T>),
    Insert(Insert<T>),
}

impl<T> DeltaOperation<T>
where
    T: OperationAttributes,
{
    pub fn delete(n: usize) -> Self {
        Self::Delete(n)
    }

    /// Create a [Retain] operation with the given attributes
    pub fn retain_with_attributes(n: usize, attributes: T) -> Self {
        Self::Retain(Retain { n, attributes })
    }

    /// Create a [Retain] operation without attributes
    pub fn retain(n: usize) -> Self {
        Self::Retain(Retain {
            n,
            attributes: T::default(),
        })
    }

    /// Create a [Insert] operation with the given attributes
    pub fn insert_with_attributes(s: &str, attributes: T) -> Self {
        Self::Insert(Insert {
            s: OTString::from(s),
            attributes,
        })
    }

    /// Create a [Insert] operation without attributes
    pub fn insert(s: &str) -> Self {
        Self::Insert(Insert {
            s: OTString::from(s),
            attributes: T::default(),
        })
    }

    /// Return the String if the operation is [Insert] operation, otherwise return the empty string.
    pub fn get_data(&self) -> &str {
        match self {
            DeltaOperation::Delete(_) => "",
            DeltaOperation::Retain(_) => "",
            DeltaOperation::Insert(insert) => &insert.s,
        }
    }

    pub fn get_attributes(&self) -> T {
        match self {
            DeltaOperation::Delete(_) => T::default(),
            DeltaOperation::Retain(retain) => retain.attributes.clone(),
            DeltaOperation::Insert(insert) => insert.attributes.clone(),
        }
    }

    pub fn set_attributes(&mut self, attributes: T) {
        match self {
            DeltaOperation::Delete(_) => log::error!("Delete should not contains attributes"),
            DeltaOperation::Retain(retain) => retain.attributes = attributes,
            DeltaOperation::Insert(insert) => insert.attributes = attributes,
        }
    }

    pub fn has_attribute(&self) -> bool {
        !self.get_attributes().is_empty()
    }

    pub fn len(&self) -> usize {
        match self {
            DeltaOperation::Delete(n) => *n,
            DeltaOperation::Retain(r) => r.n,
            DeltaOperation::Insert(i) => i.utf16_size(),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    #[allow(dead_code)]
    pub fn split(&self, index: usize) -> (Option<DeltaOperation<T>>, Option<DeltaOperation<T>>) {
        debug_assert!(index < self.len());
        let left;
        let right;
        match self {
            DeltaOperation::Delete(n) => {
                left = Some(DeltaOperation::<T>::delete(index));
                right = Some(DeltaOperation::<T>::delete(*n - index));
            }
            DeltaOperation::Retain(retain) => {
                left = Some(DeltaOperation::<T>::delete(index));
                right = Some(DeltaOperation::<T>::delete(retain.n - index));
            }
            DeltaOperation::Insert(insert) => {
                let attributes = self.get_attributes();
                left = Some(DeltaOperation::<T>::insert_with_attributes(
                    &insert.s[0..index],
                    attributes.clone(),
                ));
                right = Some(DeltaOperation::<T>::insert_with_attributes(
                    &insert.s[index..insert.utf16_size()],
                    attributes,
                ));
            }
        }

        (left, right)
    }

    /// Returns an operation with the specified width.
    /// # Arguments
    ///
    /// * `interval`: Specify the shrink width of the operation.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{Interval, DeltaOperation, EmptyAttributes};
    /// let operation = DeltaOperation::<EmptyAttributes>::insert("1234");
    ///
    /// let op1 = operation.shrink(Interval::new(0,3)).unwrap();
    /// assert_eq!(op1 , DeltaOperation::insert("123"));
    ///
    /// let op2= operation.shrink(Interval::new(3,4)).unwrap();
    /// assert_eq!(op2, DeltaOperation::insert("4"));
    /// ```
    pub fn shrink(&self, interval: Interval) -> Option<DeltaOperation<T>> {
        let op = match self {
            DeltaOperation::Delete(n) => DeltaOperation::delete(min(*n, interval.size())),
            DeltaOperation::Retain(retain) => {
                DeltaOperation::retain_with_attributes(min(retain.n, interval.size()), retain.attributes.clone())
            }
            DeltaOperation::Insert(insert) => {
                if interval.start > insert.utf16_size() {
                    DeltaOperation::insert("")
                } else {
                    let s = insert.s.sub_str(interval).unwrap_or_else(|| "".to_owned());
                    DeltaOperation::insert_with_attributes(&s, insert.attributes.clone())
                }
            }
        };

        match op.is_empty() {
            true => None,
            false => Some(op),
        }
    }

    pub fn is_delete(&self) -> bool {
        if let DeltaOperation::Delete(_) = self {
            return true;
        }
        false
    }

    pub fn is_insert(&self) -> bool {
        if let DeltaOperation::Insert(_) = self {
            return true;
        }
        false
    }

    pub fn is_retain(&self) -> bool {
        if let DeltaOperation::Retain(_) = self {
            return true;
        }
        false
    }

    pub fn is_plain(&self) -> bool {
        match self {
            DeltaOperation::Delete(_) => true,
            DeltaOperation::Retain(retain) => retain.is_plain(),
            DeltaOperation::Insert(insert) => insert.is_plain(),
        }
    }
}

impl<T> fmt::Display for DeltaOperation<T>
where
    T: OperationAttributes,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("{")?;
        match self {
            DeltaOperation::Delete(n) => {
                f.write_fmt(format_args!("delete: {}", n))?;
            }
            DeltaOperation::Retain(r) => {
                f.write_fmt(format_args!("{}", r))?;
            }
            DeltaOperation::Insert(i) => {
                f.write_fmt(format_args!("{}", i))?;
            }
        }
        f.write_str("}")?;
        Ok(())
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Retain<T: OperationAttributes> {
    pub n: usize,
    pub attributes: T,
}

impl<T> fmt::Display for Retain<T>
where
    T: OperationAttributes,
{
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        if self.attributes.is_empty() {
            f.write_fmt(format_args!("retain: {}", self.n))
        } else {
            f.write_fmt(format_args!("retain: {}, attributes: {}", self.n, self.attributes))
        }
    }
}

impl<T> Retain<T>
where
    T: OperationAttributes,
{
    pub fn merge_or_new(&mut self, n: usize, attributes: T) -> Option<DeltaOperation<T>> {
        // tracing::trace!(
        //     "merge_retain_or_new_op: len: {:?}, l: {} - r: {}",
        //     n,
        //     self.attributes,
        //     attributes
        // );
        if self.attributes == attributes {
            self.n += n;
            None
        } else {
            Some(DeltaOperation::retain_with_attributes(n, attributes))
        }
    }

    pub fn is_plain(&self) -> bool {
        self.attributes.is_empty()
    }
}

impl<T> std::convert::From<usize> for Retain<T>
where
    T: OperationAttributes,
{
    fn from(n: usize) -> Self {
        Retain {
            n,
            attributes: T::default(),
        }
    }
}

impl<T> Deref for Retain<T>
where
    T: OperationAttributes,
{
    type Target = usize;

    fn deref(&self) -> &Self::Target {
        &self.n
    }
}

impl<T> DerefMut for Retain<T>
where
    T: OperationAttributes,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.n
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Insert<T: OperationAttributes> {
    pub s: OTString,
    pub attributes: T,
}

impl<T> fmt::Display for Insert<T>
where
    T: OperationAttributes,
{
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let mut s = self.s.clone();
        if s.ends_with('\n') {
            s.pop();
            if s.is_empty() {
                s = "new_line".into();
            }
        }

        if self.attributes.is_empty() {
            f.write_fmt(format_args!("insert: {}", s))
        } else {
            f.write_fmt(format_args!("insert: {}, attributes: {}", s, self.attributes))
        }
    }
}

impl<T> Insert<T>
where
    T: OperationAttributes,
{
    pub fn utf16_size(&self) -> usize {
        self.s.utf16_len()
    }

    pub fn merge_or_new_op(&mut self, s: &str, attributes: T) -> Option<DeltaOperation<T>> {
        if self.attributes == attributes {
            self.s += s;
            None
        } else {
            Some(DeltaOperation::<T>::insert_with_attributes(s, attributes))
        }
    }

    pub fn is_plain(&self) -> bool {
        self.attributes.is_empty()
    }
}

impl<T> std::convert::From<String> for Insert<T>
where
    T: OperationAttributes,
{
    fn from(s: String) -> Self {
        Insert {
            s: s.into(),
            attributes: T::default(),
        }
    }
}

impl<T> std::convert::From<&str> for Insert<T>
where
    T: OperationAttributes,
{
    fn from(s: &str) -> Self {
        Insert::from(s.to_owned())
    }
}

impl<T> std::convert::From<OTString> for Insert<T>
where
    T: OperationAttributes,
{
    fn from(s: OTString) -> Self {
        Insert {
            s,
            attributes: T::default(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Default, Serialize, Deserialize)]
pub struct EmptyAttributes();
impl fmt::Display for EmptyAttributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("PhantomAttributes")
    }
}

impl OperationAttributes for EmptyAttributes {}

impl OperationTransform for EmptyAttributes {
    fn compose(&self, _other: &Self) -> Result<Self, OTError> {
        Ok(self.clone())
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError> {
        Ok((self.clone(), other.clone()))
    }

    fn invert(&self, _other: &Self) -> Self {
        self.clone()
    }
}
