use crate::core::{Attributes, Delta, Operation};

pub struct DeltaBuilder {
    delta: Delta,
}

impl DeltaBuilder {
    pub fn new() -> Self {
        Self {
            delta: Delta::new(),
        }
    }

    pub fn retain_with_attributes(mut self, n: usize, attrs: Attributes) -> Self {
        self.delta.retain(n, attrs);
        self
    }

    pub fn retain(mut self, n: usize) -> Self {
        self.delta.retain(n, Attributes::empty());
        self
    }

    pub fn delete(mut self, n: usize) -> Self {
        self.delta.delete(n);
        self
    }

    pub fn insert_with_attributes(mut self, s: &str, attrs: Attributes) -> Self {
        self.delta.insert(s, attrs);
        self
    }

    pub fn insert(mut self, s: &str) -> Self {
        self.delta.insert(s, Attributes::empty());
        self
    }

    pub fn trim(mut self) -> Self {
        trim(&mut self.delta);
        self
    }

    pub fn build(self) -> Delta { self.delta }
}

pub fn trim(delta: &mut Delta) {
    let remove_last = match delta.ops.last() {
        None => false,
        Some(op) => match op {
            Operation::Delete(_) => false,
            Operation::Retain(retain) => retain.is_plain(),
            Operation::Insert(_) => false,
        },
    };
    if remove_last {
        delta.ops.pop();
    }
}
