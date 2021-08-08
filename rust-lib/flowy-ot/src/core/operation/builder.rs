use crate::core::{Attributes, Operation};

pub struct Builder {
    ty: Operation,
    attrs: Attributes,
}

impl Builder {
    pub fn new(ty: Operation) -> Builder {
        Builder {
            ty,
            attrs: Attributes::Empty,
        }
    }

    pub fn retain(n: usize) -> Builder { Builder::new(Operation::Retain(n.into())) }

    pub fn delete(n: usize) -> Builder { Builder::new(Operation::Delete(n)) }

    pub fn insert(s: &str) -> Builder { Builder::new(Operation::Insert(s.into())) }

    pub fn attributes(mut self, attrs: Attributes) -> Builder {
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
