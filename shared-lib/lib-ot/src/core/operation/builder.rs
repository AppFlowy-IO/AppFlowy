use crate::{
    core::{Attributes, Operation},
    rich_text::RichTextAttributes,
};

pub type RichTextOpBuilder = OpBuilder<RichTextAttributes>;

pub struct OpBuilder<T: Attributes> {
    ty: Operation<T>,
    attrs: T,
}

impl<T> OpBuilder<T>
where
    T: Attributes,
{
    pub fn new(ty: Operation<T>) -> OpBuilder<T> {
        OpBuilder {
            ty,
            attrs: T::default(),
        }
    }

    pub fn retain(n: usize) -> OpBuilder<T> { OpBuilder::new(Operation::Retain(n.into())) }

    pub fn delete(n: usize) -> OpBuilder<T> { OpBuilder::new(Operation::Delete(n)) }

    pub fn insert(s: &str) -> OpBuilder<T> { OpBuilder::new(Operation::Insert(s.into())) }

    pub fn attributes(mut self, attrs: T) -> OpBuilder<T> {
        self.attrs = attrs;
        self
    }

    pub fn build(self) -> Operation<T> {
        let mut operation = self.ty;
        match &mut operation {
            Operation::Delete(_) => {},
            Operation::Retain(retain) => retain.attributes = self.attrs,
            Operation::Insert(insert) => insert.attributes = self.attrs,
        }
        operation
    }
}
