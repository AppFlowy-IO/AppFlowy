use crate::core::operation::{Attributes, Operation, PlainTextAttributes};
use crate::rich_text::RichTextAttributes;

pub type RichTextOpBuilder = OperationBuilder<RichTextAttributes>;
pub type PlainTextOpBuilder = OperationBuilder<PlainTextAttributes>;

pub struct OperationBuilder<T: Attributes> {
    ty: Operation<T>,
    attrs: T,
}

impl<T> OperationBuilder<T>
where
    T: Attributes,
{
    pub fn new(ty: Operation<T>) -> OperationBuilder<T> {
        OperationBuilder {
            ty,
            attrs: T::default(),
        }
    }

    pub fn retain(n: usize) -> OperationBuilder<T> {
        OperationBuilder::new(Operation::Retain(n.into()))
    }

    pub fn delete(n: usize) -> OperationBuilder<T> {
        OperationBuilder::new(Operation::Delete(n))
    }

    pub fn insert(s: &str) -> OperationBuilder<T> {
        OperationBuilder::new(Operation::Insert(s.into()))
    }

    pub fn attributes(mut self, attrs: T) -> OperationBuilder<T> {
        self.attrs = attrs;
        self
    }

    pub fn build(self) -> Operation<T> {
        let mut operation = self.ty;
        match &mut operation {
            Operation::Delete(_) => {}
            Operation::Retain(retain) => retain.attributes = self.attrs,
            Operation::Insert(insert) => insert.attributes = self.attrs,
        }
        operation
    }
}
