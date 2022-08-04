use crate::core::operation::{Attributes, Operation, PhantomAttributes};
use crate::rich_text::RichTextAttributes;

pub type RichTextOpBuilder = OperationsBuilder<RichTextAttributes>;
pub type PlainTextOpBuilder = OperationsBuilder<PhantomAttributes>;

pub struct OperationsBuilder<T: Attributes> {
    operations: Vec<Operation<T>>,
}

impl<T> OperationsBuilder<T>
where
    T: Attributes,
{
    pub fn new() -> OperationsBuilder<T> {
        OperationsBuilder { operations: vec![] }
    }

    pub fn retain_with_attributes(mut self, n: usize, attributes: T) -> OperationsBuilder<T> {
        let retain = Operation::retain_with_attributes(n.into(), attributes);
        self.operations.push(retain);
        self
    }

    pub fn retain(mut self, n: usize) -> OperationsBuilder<T> {
        let retain = Operation::retain(n.into());
        self.operations.push(retain);
        self
    }

    pub fn delete(mut self, n: usize) -> OperationsBuilder<T> {
        self.operations.push(Operation::Delete(n));
        self
    }

    pub fn insert_with_attributes(mut self, s: &str, attributes: T) -> OperationsBuilder<T> {
        let insert = Operation::insert_with_attributes(s.into(), attributes);
        self.operations.push(insert);
        self
    }

    pub fn insert(mut self, s: &str) -> OperationsBuilder<T> {
        let insert = Operation::insert(s.into());
        self.operations.push(insert);
        self
    }

    pub fn build(self) -> Vec<Operation<T>> {
        self.operations
    }
}
