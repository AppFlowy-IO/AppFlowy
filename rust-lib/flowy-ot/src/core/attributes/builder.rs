use crate::core::{Attribute, AttributeKey, AttributeValue, Attributes, REMOVE_FLAG};

pub struct AttributeBuilder {
    inner: Attributes,
}

macro_rules! impl_bool_attribute {
    ($name: ident,$key: expr) => {
        pub fn $name(self, value: bool) -> Self {
            let value = match value {
                true => "true",
                false => REMOVE_FLAG,
            };
            self.insert($key, value)
        }
    };
}

macro_rules! impl_str_attribute {
    ($name: ident,$key: expr) => {
        pub fn $name(self, s: &str, value: bool) -> Self {
            let value = match value {
                true => s,
                false => REMOVE_FLAG,
            };
            self.insert($key, value)
        }
    };
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

    pub fn insert<T: Into<AttributeValue>>(mut self, key: AttributeKey, value: T) -> Self {
        self.inner.add(key.value(value));
        self
    }

    pub fn remove<T: Into<String>>(mut self, key: AttributeKey) -> Self {
        self.inner.add(key.value(REMOVE_FLAG));
        self
    }

    // AttributeBuilder::new().bold(true).build()
    impl_bool_attribute!(bold, AttributeKey::Bold);
    impl_bool_attribute!(italic, AttributeKey::Italic);
    impl_bool_attribute!(underline, AttributeKey::Underline);
    impl_bool_attribute!(strike_through, AttributeKey::StrikeThrough);
    impl_str_attribute!(link, AttributeKey::Link);

    pub fn build(self) -> Attributes { self.inner }
}
