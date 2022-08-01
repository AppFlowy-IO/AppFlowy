use crate::core::operation::{Attributes, Operation, PhantomAttributes};
use crate::rich_text::RichTextAttributes;

pub type RichTextOpBuilder = OperationBuilder<RichTextAttributes>;
pub type PlainTextOpBuilder = OperationBuilder<PhantomAttributes>;

pub struct OperationBuilder<T: Attributes> {
    operations: Vec<Operation<T>>,
}

impl<T> OperationBuilder<T>
where
    T: Attributes,
{
    pub fn new() -> OperationBuilder<T> {
        OperationBuilder { operations: vec![] }
    }

    pub fn retain(mut self, n: usize) -> OperationBuilder<T> {
        let mut retain = Operation::Retain(n.into());

        if let Some(attributes) = attributes {
            if let Operation::Retain(r) = &mut retain {
                r.attributes = attributes;
            }
        }
        self.operations.push(retain);
        self
    }

    pub fn delete(mut self, n: usize) -> OperationBuilder<T> {
        self.operations.push(Operation::Delete(n));
        self
    }

    pub fn insert(mut self, s: &str, attributes: Option<T>) -> OperationBuilder<T> {
        let mut insert = Operation::Insert(s.into());
        if let Some(attributes) = attributes {
            if let Operation::Retain(i) = &mut insert {
                i.attributes = attributes;
            }
        }
        self.operations.push(insert);
        self
    }

    pub fn attributes(mut self, attrs: T) -> OperationBuilder<T> {
        self.attrs = attrs;
        self
    }

    pub fn build(self) -> Vec<Operation<T>> {
        self.operations
    }
}
