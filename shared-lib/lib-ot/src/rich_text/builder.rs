#![allow(non_snake_case)]
#![allow(clippy::derivable_impls)]
use crate::rich_text::{RichTextAttribute, RichTextAttributes};

pub struct AttributeBuilder {
    inner: RichTextAttributes,
}

impl std::default::Default for AttributeBuilder {
    fn default() -> Self {
        Self {
            inner: RichTextAttributes::default(),
        }
    }
}

impl AttributeBuilder {
    pub fn new() -> Self {
        AttributeBuilder::default()
    }

    pub fn add_attr(mut self, attribute: RichTextAttribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn build(self) -> RichTextAttributes {
        self.inner
    }
}
