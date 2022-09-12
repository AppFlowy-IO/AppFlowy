#![allow(non_snake_case)]
#![allow(clippy::derivable_impls)]
use crate::text_delta::{TextAttribute, TextAttributes};

pub struct TextDeltaAttributeBuilder {
    inner: TextAttributes,
}

impl std::default::Default for TextDeltaAttributeBuilder {
    fn default() -> Self {
        Self {
            inner: TextAttributes::default(),
        }
    }
}

impl TextDeltaAttributeBuilder {
    pub fn new() -> Self {
        TextDeltaAttributeBuilder::default()
    }

    pub fn add_attr(mut self, attribute: TextAttribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn build(self) -> TextAttributes {
        self.inner
    }
}
