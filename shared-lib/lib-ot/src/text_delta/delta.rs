use crate::core::{AttributeHashMap, DeltaOperation, DeltaOperationBuilder, DeltaOperations};

pub type DeltaTextOperations = DeltaOperations<AttributeHashMap>;
pub type DeltaTextOperationBuilder = DeltaOperationBuilder<AttributeHashMap>;
pub type DeltaTextOperation = DeltaOperation<AttributeHashMap>;

// pub trait TextOperation2: Default + Debug + OperationTransform {}
//
// impl TextOperation2 for TextOperations {}
