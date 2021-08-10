use crate::core::{Attributes, Builder, Interval};
use bytecount::num_chars;
use serde::__private::Formatter;
use std::{
    cmp::min,
    fmt,
    ops::{Deref, DerefMut},
    str::Chars,
};

#[derive(Debug, Clone, PartialEq)]
pub enum Operation {
    Delete(usize),
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
            Operation::Delete(_) => Attributes::default(),
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
            Attributes::Follow => false,
            Attributes::Custom(data) => !data.is_empty(),
        }
    }

    pub fn length(&self) -> usize {
        match self {
            Operation::Delete(n) => *n,
            Operation::Retain(r) => r.n,
            Operation::Insert(i) => i.num_chars(),
        }
    }

    pub fn is_empty(&self) -> bool { self.length() == 0 }

    pub fn shrink(&self, interval: Interval) -> Option<Operation> {
        let op = match self {
            Operation::Delete(n) => Builder::delete(min(*n, interval.size())).build(),
            Operation::Retain(retain) => Builder::retain(min(retain.n, interval.size()))
                .attributes(retain.attributes.clone())
                .build(),
            Operation::Insert(insert) => {
                if interval.start > insert.s.len() {
                    Builder::insert("").build()
                } else {
                    let s = &insert.s[interval.start..min(interval.end, insert.s.len())];
                    Builder::insert(s)
                        .attributes(insert.attributes.clone())
                        .build()
                }
            },
        };

        match op.is_empty() {
            true => None,
            false => Some(op),
        }
    }
}

impl fmt::Display for Operation {
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

#[derive(Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Retain {
    #[serde(rename(serialize = "retain", deserialize = "retain"))]
    pub n: usize,
    #[serde(skip_serializing_if = "is_empty")]
    pub attributes: Attributes,
}

impl fmt::Display for Retain {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        f.write_fmt(format_args!(
            "retain: {}, attributes: {}",
            self.n, self.attributes
        ))
    }
}

impl Retain {
    pub fn merge_or_new_op(&mut self, n: usize, attributes: Attributes) -> Option<Operation> {
        log::debug!(
            "merge_retain_or_new_op: len: {:?}, l: {} - r: {}",
            n,
            self.attributes,
            attributes
        );

        match &attributes {
            Attributes::Follow => {
                log::debug!("Follow attribute: {:?}", self.attributes);
                self.n += n;
                None
            },
            Attributes::Custom(_) => {
                if self.attributes == attributes {
                    self.n += n;
                    None
                } else {
                    Some(Builder::retain(n).attributes(attributes).build())
                }
            },
        }
    }

    pub fn is_plain(&self) -> bool {
        match &self.attributes {
            Attributes::Follow => true,
            Attributes::Custom(data) => data.is_empty(),
        }
    }
}

impl std::convert::From<usize> for Retain {
    fn from(n: usize) -> Self {
        Retain {
            n,
            attributes: Attributes::default(),
        }
    }
}

impl Deref for Retain {
    type Target = usize;

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

impl fmt::Display for Insert {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let mut s = self.s.clone();
        if s.ends_with("\n") {
            s.pop();
            if s.is_empty() {
                s = "new_line".to_owned();
            }
        }

        f.write_fmt(format_args!(
            "insert: {}, attributes: {}",
            s, self.attributes
        ))
    }
}

impl Insert {
    pub fn as_bytes(&self) -> &[u8] { self.s.as_bytes() }

    pub fn chars(&self) -> Chars<'_> { self.s.chars() }

    pub fn num_chars(&self) -> usize { num_chars(self.s.as_bytes()) as _ }

    pub fn merge_or_new_op(&mut self, s: &str, attributes: Attributes) -> Option<Operation> {
        match &attributes {
            Attributes::Follow => {
                self.s += s;
                return None;
            },
            Attributes::Custom(_) => {
                if self.attributes == attributes {
                    self.s += s;
                    None
                } else {
                    Some(Builder::insert(s).attributes(attributes).build())
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

fn is_empty(attributes: &Attributes) -> bool {
    match attributes {
        Attributes::Follow => true,
        Attributes::Custom(data) => data.is_empty(),
    }
}
