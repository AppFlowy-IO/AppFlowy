#![allow(non_snake_case)]
use crate::core::{Attribute, Attributes};
pub struct AttributeBuilder {
    inner: Attributes,
}

impl std::default::Default for AttributeBuilder {
    fn default() -> Self {
        Self {
            inner: Attributes::default(),
        }
    }
}

impl AttributeBuilder {
    pub fn new() -> Self { AttributeBuilder::default() }

    pub fn add_attr(mut self, attribute: Attribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn build(self) -> Attributes { self.inner }
}
