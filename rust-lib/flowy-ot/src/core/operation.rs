use crate::core::{transform_attributes, Attributes};
use bytecount::num_chars;
use std::{
    fmt,
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

    pub fn get_attributes(&self) -> Attributes {
        match self {
            Operation::Delete(_) => Attributes::Empty,
            Operation::Retain(retain) => retain.attributes.clone(),
            Operation::Insert(insert) => insert.attributes.clone(),
        }
    }

    pub fn set_attributes(&mut self, attributes: Attributes) {
        match self {
            Operation::Delete(_) => {
                log::error!("Delete should not contains attributes");
            },
            Operation::Retain(retain) => {
                retain.attributes = attributes;
            },
            Operation::Insert(insert) => {
                insert.attributes = attributes;
            },
        }
    }

    pub fn has_attribute(&self) -> bool {
        match self.get_attributes() {
            Attributes::Follow => true,
            Attributes::Custom(_) => false,
            Attributes::Empty => true,
        }
    }

    pub fn length(&self) -> u64 {
        match self {
            Operation::Delete(n) => *n,
            Operation::Retain(r) => r.n,
            Operation::Insert(i) => i.num_chars(),
        }
    }

    pub fn is_empty(&self) -> bool { self.length() == 0 }
}

impl fmt::Display for Operation {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Operation::Delete(n) => {
                f.write_fmt(format_args!("delete: {}", n))?;
            },
            Operation::Retain(r) => {
                f.write_fmt(format_args!(
                    "retain: {}, attributes: {}",
                    r.n, r.attributes
                ))?;
            },
            Operation::Insert(i) => {
                f.write_fmt(format_args!(
                    "insert: {}, attributes: {}",
                    i.s, i.attributes
                ))?;
            },
        }
        Ok(())
    }
}

pub struct OpBuilder {
    ty: Operation,
    attrs: Attributes,
}

impl OpBuilder {
    pub fn new(ty: Operation) -> OpBuilder {
        OpBuilder {
            ty,
            attrs: Attributes::Empty,
        }
    }

    pub fn retain(n: u64) -> OpBuilder { OpBuilder::new(Operation::Retain(n.into())) }

    pub fn delete(n: u64) -> OpBuilder { OpBuilder::new(Operation::Delete(n)) }

    pub fn insert(s: &str) -> OpBuilder { OpBuilder::new(Operation::Insert(s.into())) }

    pub fn attributes(mut self, attrs: Attributes) -> OpBuilder {
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
    #[serde(skip_serializing_if = "is_empty")]
    pub attributes: Attributes,
}

impl Retain {
    pub fn merge_or_new_op(&mut self, n: u64, attributes: Attributes) -> Option<Operation> {
        log::debug!(
            "merge_retain_or_new_op: {:?}, {:?}",
            self.attributes,
            attributes
        );

        match &attributes {
            Attributes::Follow => {
                self.n += n;
                None
            },
            Attributes::Custom(_) | Attributes::Empty => {
                if self.attributes == attributes {
                    self.n += n;
                    None
                } else {
                    Some(OpBuilder::retain(n).attributes(attributes).build())
                }
            },
        }
    }
}

impl std::convert::From<u64> for Retain {
    fn from(n: u64) -> Self {
        Retain {
            n,
            attributes: Attributes::default(),
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

    #[serde(skip_serializing_if = "is_empty")]
    pub attributes: Attributes,
}

impl Insert {
    pub fn as_bytes(&self) -> &[u8] { self.s.as_bytes() }

    pub fn chars(&self) -> Chars<'_> { self.s.chars() }

    pub fn num_chars(&self) -> u64 { num_chars(self.s.as_bytes()) as _ }

    pub fn merge_or_new_op(&mut self, s: &str, attributes: Attributes) -> Option<Operation> {
        match &attributes {
            Attributes::Follow => {
                self.s += s;
                return None;
            },
            Attributes::Custom(_) | Attributes::Empty => {
                if self.attributes == attributes {
                    self.s += s;
                    None
                } else {
                    Some(OpBuilder::insert(s).attributes(attributes).build())
                }
            },
        }
    }
}

impl std::convert::From<String> for Insert {
    fn from(s: String) -> Self {
        Insert {
            s,
            attributes: Attributes::default(),
        }
    }
}

impl std::convert::From<&str> for Insert {
    fn from(s: &str) -> Self { Insert::from(s.to_owned()) }
}

fn is_empty(attributes: &Attributes) -> bool { attributes.is_empty() }
