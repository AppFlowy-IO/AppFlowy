use crate::core::delta::operation::{DeltaOperation, EmptyAttributes, OperationAttributes};

// pub type RichTextOpBuilder = OperationsBuilder<TextAttributes>;
pub type PlainTextOpBuilder = OperationsBuilder<EmptyAttributes>;

#[derive(Default)]
pub struct OperationsBuilder<T: OperationAttributes> {
    operations: Vec<DeltaOperation<T>>,
}

impl<T> OperationsBuilder<T>
where
    T: OperationAttributes,
{
    pub fn new() -> OperationsBuilder<T> {
        OperationsBuilder::default()
    }

    pub fn retain_with_attributes(mut self, n: usize, attributes: T) -> OperationsBuilder<T> {
        let retain = DeltaOperation::retain_with_attributes(n, attributes);
        self.operations.push(retain);
        self
    }

    pub fn retain(mut self, n: usize) -> OperationsBuilder<T> {
        let retain = DeltaOperation::retain(n);
        self.operations.push(retain);
        self
    }

    pub fn delete(mut self, n: usize) -> OperationsBuilder<T> {
        self.operations.push(DeltaOperation::Delete(n));
        self
    }

    pub fn insert_with_attributes(mut self, s: &str, attributes: T) -> OperationsBuilder<T> {
        let insert = DeltaOperation::insert_with_attributes(s, attributes);
        self.operations.push(insert);
        self
    }

    pub fn insert(mut self, s: &str) -> OperationsBuilder<T> {
        let insert = DeltaOperation::insert(s);
        self.operations.push(insert);
        self
    }

    pub fn build(self) -> Vec<DeltaOperation<T>> {
        self.operations
    }
}
