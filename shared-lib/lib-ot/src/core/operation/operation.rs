use crate::{
    core::{FlowyStr, Interval, OpBuilder, OperationTransformable},
    errors::OTError,
};
use serde::{Deserialize, Serialize, __private::Formatter};
use std::{
    cmp::min,
    fmt,
    fmt::Debug,
    ops::{Deref, DerefMut},
};

pub trait Attributes: fmt::Display + Eq + PartialEq + Default + Clone + Debug + OperationTransformable {
    fn is_empty(&self) -> bool;

    // Remove the empty attribute which value is None.
    fn remove_empty(&mut self);

    fn extend_other(&mut self, other: Self);
}

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

    pub fn has_attribute(&self) -> bool { !self.get_attributes().is_empty() }

    pub fn len(&self) -> usize {
        match self {
            Operation::Delete(n) => *n,
            Operation::Retain(r) => r.n,
            Operation::Insert(i) => i.utf16_size(),
        }
    }

    pub fn is_empty(&self) -> bool { self.len() == 0 }

    #[allow(dead_code)]
    pub fn split(&self, index: usize) -> (Option<Operation<T>>, Option<Operation<T>>) {
        debug_assert!(index < self.len());
        let left;
        let right;
        match self {
            Operation::Delete(n) => {
                left = Some(OpBuilder::<T>::delete(index).build());
                right = Some(OpBuilder::<T>::delete(*n - index).build());
            },
            Operation::Retain(retain) => {
                left = Some(OpBuilder::<T>::delete(index).build());
                right = Some(OpBuilder::<T>::delete(retain.n - index).build());
            },
            Operation::Insert(insert) => {
                let attributes = self.get_attributes();
                left = Some(
                    OpBuilder::<T>::insert(&insert.s[0..index])
                        .attributes(attributes.clone())
                        .build(),
                );
                right = Some(
                    OpBuilder::<T>::insert(&insert.s[index..insert.utf16_size()])
                        .attributes(attributes)
                        .build(),
                );
            },
        }

        (left, right)
    }

    pub fn shrink(&self, interval: Interval) -> Option<Operation<T>> {
        let op = match self {
            Operation::Delete(n) => OpBuilder::delete(min(*n, interval.size())).build(),
            Operation::Retain(retain) => OpBuilder::retain(min(retain.n, interval.size()))
                .attributes(retain.attributes.clone())
                .build(),
            Operation::Insert(insert) => {
                if interval.start > insert.utf16_size() {
                    OpBuilder::insert("").build()
                } else {
                    let s = insert.s.sub_str(interval).unwrap_or_else(|| "".to_owned());
                    OpBuilder::insert(&s).attributes(insert.attributes.clone()).build()
                }
            },
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
            },
            Operation::Retain(r) => {
                f.write_fmt(format_args!("{}", r))?;
            },
            Operation::Insert(i) => {
                f.write_fmt(format_args!("{}", i))?;
            },
        }
        f.write_str("}")?;
        Ok(())
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Retain<T: Attributes> {
    // #[serde(rename(serialize = "retain", deserialize = "retain"))]
    pub n: usize,
    // #[serde(skip_serializing_if = "is_empty")]
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
            Some(OpBuilder::retain(n).attributes(attributes).build())
        }
    }

    pub fn is_plain(&self) -> bool { self.attributes.is_empty() }
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

    fn deref(&self) -> &Self::Target { &self.n }
}

impl<T> DerefMut for Retain<T>
where
    T: Attributes,
{
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.n }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Insert<T: Attributes> {
    // #[serde(rename(serialize = "insert", deserialize = "insert"))]
    pub s: FlowyStr,

    // #[serde(skip_serializing_if = "is_empty")]
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
    pub fn utf16_size(&self) -> usize { self.s.utf16_size() }

    pub fn merge_or_new_op(&mut self, s: &str, attributes: T) -> Option<Operation<T>> {
        if self.attributes == attributes {
            self.s += s;
            None
        } else {
            Some(OpBuilder::<T>::insert(s).attributes(attributes).build())
        }
    }

    pub fn is_plain(&self) -> bool { self.attributes.is_empty() }
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
    fn from(s: &str) -> Self { Insert::from(s.to_owned()) }
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
pub struct PlainTextAttributes();
impl fmt::Display for PlainTextAttributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_str("PlainTextAttributes") }
}

impl Attributes for PlainTextAttributes {
    fn is_empty(&self) -> bool { true }

    fn remove_empty(&mut self) {}

    fn extend_other(&mut self, _other: Self) {}
}

impl OperationTransformable for PlainTextAttributes {
    fn compose(&self, _other: &Self) -> Result<Self, OTError> { Ok(self.clone()) }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError> { Ok((self.clone(), other.clone())) }

    fn invert(&self, _other: &Self) -> Self { self.clone() }
}
