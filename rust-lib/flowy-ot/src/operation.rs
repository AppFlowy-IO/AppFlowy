use crate::attributes::Attributes;
use std::{
    cmp::Ordering,
    collections::{hash_map::RandomState, HashMap},
    ops::Deref,
};

#[derive(Clone, Debug, PartialEq)]
pub struct Operation {
    pub ty: OpType,
    pub attrs: Attributes,
}

impl Operation {
    pub fn delete(&mut self, n: u64) { self.ty.delete(n); }

    pub fn retain(&mut self, n: u64) { self.ty.retain(n); }

    pub fn is_plain(&self) -> bool { self.attrs.is_empty() }

    pub fn is_noop(&self) -> bool {
        match self.ty {
            OpType::Retain(_) => true,
            _ => false,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum OpType {
    Delete(u64),
    Retain(u64),
    Insert(String),
}

impl OpType {
    pub fn is_delete(&self) -> bool {
        match self {
            OpType::Delete(_) => true,
            _ => false,
        }
    }

    pub fn is_retain(&self) -> bool {
        match self {
            OpType::Retain(_) => true,
            _ => false,
        }
    }

    pub fn is_insert(&self) -> bool {
        match self {
            OpType::Insert(_) => true,
            _ => false,
        }
    }

    pub fn delete(&mut self, n: u64) {
        debug_assert_eq!(self.is_delete(), true);
        if let OpType::Delete(n_last) = self {
            *n_last += n;
        }
    }

    pub fn retain(&mut self, n: u64) {
        debug_assert_eq!(self.is_retain(), true);
        if let OpType::Retain(i_last) = self {
            *i_last += n;
        }
    }
}

pub struct OperationBuilder {
    ty: OpType,
    attrs: Attributes,
}

impl OperationBuilder {
    pub fn new(ty: OpType) -> OperationBuilder {
        OperationBuilder {
            ty,
            attrs: Attributes::default(),
        }
    }

    pub fn retain(n: u64) -> OperationBuilder { OperationBuilder::new(OpType::Retain(n)) }

    pub fn delete(n: u64) -> OperationBuilder { OperationBuilder::new(OpType::Delete(n)) }

    pub fn insert(s: String) -> OperationBuilder { OperationBuilder::new(OpType::Insert(s)) }

    pub fn with_attrs(mut self, attrs: Attributes) -> OperationBuilder {
        self.attrs = attrs;
        self
    }

    pub fn build(self) -> Operation {
        Operation {
            ty: self.ty,
            attrs: self.attrs,
        }
    }
}
