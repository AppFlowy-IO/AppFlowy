#![allow(non_snake_case)]
#![allow(clippy::derivable_impls)]
use crate::text_delta::{TextAttribute, TextAttributes};

pub struct AttributeBuilder {
    inner: TextAttributes,
}

impl std::default::Default for AttributeBuilder {
    fn default() -> Self {
        Self {
            inner: TextAttributes::default(),
        }
    }
}

impl AttributeBuilder {
    pub fn new() -> Self {
        AttributeBuilder::default()
    }

    pub fn add_attr(mut self, attribute: TextAttribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn build(self) -> TextAttributes {
        self.inner
    }
}
