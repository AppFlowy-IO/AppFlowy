#![allow(non_snake_case)]
use crate::core::{Attribute, Attributes};
pub struct AttributeBuilder {
    inner: Attributes,
}

impl AttributeBuilder {
    pub fn new() -> Self {
        Self {
            inner: Attributes::default(),
        }
    }

    pub fn add(mut self, attribute: Attribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn build(self) -> Attributes { self.inner }
}
