use crate::core::{Attributes, Operation};

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

    pub fn retain(n: usize) -> OpBuilder { OpBuilder::new(Operation::Retain(n.into())) }

    pub fn delete(n: usize) -> OpBuilder { OpBuilder::new(Operation::Delete(n)) }

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
