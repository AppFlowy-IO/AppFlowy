use crate::core::{Attributes, Operation, OperationBuilder, Operations};

pub type TextDelta = Operations<Attributes>;
pub type TextDeltaBuilder = OperationBuilder<Attributes>;

pub type TextOperation = Operation<Attributes>;
