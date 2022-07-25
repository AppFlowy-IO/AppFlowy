use crate::core::flowy_str::FlowyStr;
use crate::core::interval::Interval;
use crate::core::operation::OperationBuilder;
use crate::errors::OTError;
use serde::{Deserialize, Serialize, __private::Formatter};
use std::fmt::Display;
use std::{
    cmp::min,
    fmt,
    fmt::Debug,
    ops::{Deref, DerefMut},
};

pub trait OperationTransformable {
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
    ///  use lib_ot::core::{OperationTransformable, PlainTextDeltaBuilder};
    ///  let document = PlainTextDeltaBuilder::new().build();
    ///  let delta = PlainTextDeltaBuilder::new().insert("abc").build();
    ///  let new_document = document.compose(&delta).unwrap();
    ///  assert_eq!(new_document.content_str().unwrap(), "abc".to_owned());
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
    /// use lib_ot::core::{OperationTransformable, PlainTextDeltaBuilder};
    /// let original_document = PlainTextDeltaBuilder::new().build();
    /// let delta = PlainTextDeltaBuilder::new().insert("abc").build();
    ///
    /// let undo_delta = delta.invert(&original_document);
    /// let new_document = original_document.compose(&delta).unwrap();
    /// let document = new_document.compose(&undo_delta).unwrap();
    ///
    /// assert_eq!(original_document, document);
    ///
    /// ```
    fn invert(&self, other: &Self) -> Self;
}

/// Each operation can carry attributes. For example, the [RichTextAttributes] has a list of key/value attributes.
/// Such as { bold: true, italic: true }.  
///
/// Because [Operation] is generic over the T, so you must specify the T. For example, the [PlainTextDelta]. It use
/// use [PhantomAttributes] as the T. [PhantomAttributes] does nothing, just a phantom.
///
pub trait Attributes: Default + Display + Eq + PartialEq + Clone + Debug + OperationTransformable {
    fn is_empty(&self) -> bool {
        true
    }

    /// Remove the empty attribute which value is None.
    fn remove_empty(&mut self) {
        // Do nothing
    }

    fn extend_other(&mut self, _other: Self) {
        // Do nothing
    }
}

/// [Operation] consists of three types.
/// * Delete
/// * Retain
/// * Insert
///
/// The [T] should support serde if you want to serialize/deserialize the operation
/// to json string. You could check out the operation_serde.rs for more information.
///
#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Operation<T: Attributes> {
    Delete(usize),
    Retain(Retain<T>),
    Insert(Insert<T>),
}

impl<T> Operation<T>
where
    T: Attributes,
{
    pub fn get_data(&self) -> &str {
        match self {
            Operation::Delete(_) => "",
            Operation::Retain(_) => "",
            Operation::Insert(insert) => &insert.s,
        }
    }

    pub fn get_attributes(&self) -> T {
        match self {
            Operation::Delete(_) => T::default(),
            Operation::Retain(retain) => retain.attributes.clone(),
            Operation::Insert(insert) => insert.attributes.clone(),
        }
    }

    pub fn set_attributes(&mut self, attributes: T) {
        match self {
            Operation::Delete(_) => log::error!("Delete should not contains attributes"),
            Operation::Retain(retain) => retain.attributes = attributes,
            Operation::Insert(insert) => insert.attributes = attributes,
        }
    }

    pub fn has_attribute(&self) -> bool {
        !self.get_attributes().is_empty()
    }

    pub fn len(&self) -> usize {
        match self {
            Operation::Delete(n) => *n,
            Operation::Retain(r) => r.n,
            Operation::Insert(i) => i.utf16_size(),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    #[allow(dead_code)]
    pub fn split(&self, index: usize) -> (Option<Operation<T>>, Option<Operation<T>>) {
        debug_assert!(index < self.len());
        let left;
        let right;
        match self {
            Operation::Delete(n) => {
                left = Some(OperationBuilder::<T>::delete(index).build());
                right = Some(OperationBuilder::<T>::delete(*n - index).build());
            }
            Operation::Retain(retain) => {
                left = Some(OperationBuilder::<T>::delete(index).build());
                right = Some(OperationBuilder::<T>::delete(retain.n - index).build());
            }
            Operation::Insert(insert) => {
                let attributes = self.get_attributes();
                left = Some(
                    OperationBuilder::<T>::insert(&insert.s[0..index])
                        .attributes(attributes.clone())
                        .build(),
                );
                right = Some(
                    OperationBuilder::<T>::insert(&insert.s[index..insert.utf16_size()])
                        .attributes(attributes)
                        .build(),
                );
            }
        }

        (left, right)
    }

    pub fn shrink(&self, interval: Interval) -> Option<Operation<T>> {
        let op = match self {
            Operation::Delete(n) => OperationBuilder::delete(min(*n, interval.size())).build(),
            Operation::Retain(retain) => OperationBuilder::retain(min(retain.n, interval.size()))
                .attributes(retain.attributes.clone())
                .build(),
            Operation::Insert(insert) => {
                if interval.start > insert.utf16_size() {
                    OperationBuilder::insert("").build()
                } else {
                    let s = insert.s.sub_str(interval).unwrap_or_else(|| "".to_owned());
                    OperationBuilder::insert(&s)
                        .attributes(insert.attributes.clone())
                        .build()
                }
            }
        };

        match op.is_empty() {
            true => None,
            false => Some(op),
        }
    }

    pub fn is_delete(&self) -> bool {
        if let Operation::Delete(_) = self {
            return true;
        }
        false
    }

    pub fn is_insert(&self) -> bool {
        if let Operation::Insert(_) = self {
            return true;
        }
        false
    }

    pub fn is_retain(&self) -> bool {
        if let Operation::Retain(_) = self {
            return true;
        }
        false
    }

    pub fn is_plain(&self) -> bool {
        match self {
            Operation::Delete(_) => true,
            Operation::Retain(retain) => retain.is_plain(),
            Operation::Insert(insert) => insert.is_plain(),
        }
    }
}

impl<T> fmt::Display for Operation<T>
where
    T: Attributes,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("{")?;
        match self {
            Operation::Delete(n) => {
                f.write_fmt(format_args!("delete: {}", n))?;
            }
            Operation::Retain(r) => {
                f.write_fmt(format_args!("{}", r))?;
            }
            Operation::Insert(i) => {
                f.write_fmt(format_args!("{}", i))?;
            }
        }
        f.write_str("}")?;
        Ok(())
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Retain<T: Attributes> {
    pub n: usize,
    pub attributes: T,
}

impl<T> fmt::Display for Retain<T>
where
    T: Attributes,
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
    T: Attributes,
{
    pub fn merge_or_new(&mut self, n: usize, attributes: T) -> Option<Operation<T>> {
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
            Some(OperationBuilder::retain(n).attributes(attributes).build())
        }
    }

    pub fn is_plain(&self) -> bool {
        self.attributes.is_empty()
    }
}

impl<T> std::convert::From<usize> for Retain<T>
where
    T: Attributes,
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
    T: Attributes,
{
    type Target = usize;

    fn deref(&self) -> &Self::Target {
        &self.n
    }
}

impl<T> DerefMut for Retain<T>
where
    T: Attributes,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.n
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Insert<T: Attributes> {
    pub s: FlowyStr,
    pub attributes: T,
}

impl<T> fmt::Display for Insert<T>
where
    T: Attributes,
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
    T: Attributes,
{
    pub fn utf16_size(&self) -> usize {
        self.s.utf16_size()
    }

    pub fn merge_or_new_op(&mut self, s: &str, attributes: T) -> Option<Operation<T>> {
        if self.attributes == attributes {
            self.s += s;
            None
        } else {
            Some(OperationBuilder::<T>::insert(s).attributes(attributes).build())
        }
    }

    pub fn is_plain(&self) -> bool {
        self.attributes.is_empty()
    }
}

impl<T> std::convert::From<String> for Insert<T>
where
    T: Attributes,
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
    T: Attributes,
{
    fn from(s: &str) -> Self {
        Insert::from(s.to_owned())
    }
}

impl<T> std::convert::From<FlowyStr> for Insert<T>
where
    T: Attributes,
{
    fn from(s: FlowyStr) -> Self {
        Insert {
            s,
            attributes: T::default(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Default, Serialize, Deserialize)]
pub struct PhantomAttributes();
impl fmt::Display for PhantomAttributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("PhantomAttributes")
    }
}

impl Attributes for PhantomAttributes {}

impl OperationTransformable for PhantomAttributes {
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
