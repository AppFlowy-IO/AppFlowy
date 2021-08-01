use crate::attributes::Attributes;
use bytecount::num_chars;
use std::{
    cmp::Ordering,
    collections::{hash_map::RandomState, HashMap},
    ops::{Deref, DerefMut},
    str::Chars,
};

#[derive(Debug, Clone, PartialEq)]
pub enum Operation {
    Delete(u64),
    Retain(Retain),
    Insert(Insert),
}

impl Operation {
    pub fn is_delete(&self) -> bool {
        match self {
            Operation::Delete(_) => true,
            _ => false,
        }
    }

    pub fn is_noop(&self) -> bool {
        match self {
            Operation::Retain(_) => true,
            _ => false,
        }
    }

    pub fn attributes(&self) -> Option<Attributes> {
        match self {
            Operation::Delete(_) => None,
            Operation::Retain(retain) => retain.attributes.clone(),
            Operation::Insert(insert) => insert.attributes.clone(),
        }
    }

    pub fn set_attributes(&mut self, attributes: Option<Attributes>) {
        match self {
            Operation::Delete(_) => {},
            Operation::Retain(retain) => {
                retain.attributes = attributes;
            },
            Operation::Insert(insert) => {
                insert.attributes = attributes;
            },
        }
    }

    pub fn is_plain(&self) -> bool { self.attributes().is_none() }

    pub fn length(&self) -> u64 {
        match self {
            Operation::Delete(n) => *n,
            Operation::Retain(r) => r.n,
            Operation::Insert(i) => i.num_chars(),
        }
    }
}

pub struct OpBuilder {
    ty: Operation,
    attrs: Option<Attributes>,
}

impl OpBuilder {
    pub fn new(ty: Operation) -> OpBuilder { OpBuilder { ty, attrs: None } }

    pub fn retain(n: u64) -> OpBuilder { OpBuilder::new(Operation::Retain(n.into())) }

    pub fn delete(n: u64) -> OpBuilder { OpBuilder::new(Operation::Delete(n)) }

    pub fn insert(s: String) -> OpBuilder { OpBuilder::new(Operation::Insert(s.into())) }

    pub fn attributes(mut self, attrs: Option<Attributes>) -> OpBuilder {
        self.attrs = attrs;
        self
    }

    pub fn build(self) -> Operation {
        let mut operation = self.ty;
        match &mut operation {
            Operation::Delete(_) => {},
            Operation::Retain(retain) => retain.attributes = self.attrs,
            Operation::Insert(insert) => insert.attributes = self.attrs,
        }
        operation
    }
}

#[derive(Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Retain {
    #[serde(rename(serialize = "retain", deserialize = "retain"))]
    pub n: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) attributes: Option<Attributes>,
}

impl std::convert::From<u64> for Retain {
    fn from(n: u64) -> Self {
        Retain {
            n,
            attributes: None,
        }
    }
}

impl Deref for Retain {
    type Target = u64;

    fn deref(&self) -> &Self::Target { &self.n }
}

impl DerefMut for Retain {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.n }
}

#[derive(Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Insert {
    #[serde(rename(serialize = "insert", deserialize = "insert"))]
    pub s: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub attributes: Option<Attributes>,
}

impl Insert {
    pub fn as_bytes(&self) -> &[u8] { self.s.as_bytes() }

    pub fn chars(&self) -> Chars<'_> { self.s.chars() }

    pub fn num_chars(&self) -> u64 { num_chars(self.s.as_bytes()) as _ }
}

impl std::convert::From<String> for Insert {
    fn from(s: String) -> Self {
        Insert {
            s,
            attributes: None,
        }
    }
}

impl std::convert::From<&str> for Insert {
    fn from(s: &str) -> Self {
        Insert {
            s: s.to_owned(),
            attributes: None,
        }
    }
}
