use crate::core::{Attributes, REMOVE_FLAG};
use derive_more::Display;
use std::{fmt, fmt::Formatter};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AttributeValue(pub(crate) String);

impl AsRef<str> for AttributeValue {
    fn as_ref(&self) -> &str { &self.0 }
}

#[derive(Clone, Debug, Display, Hash, Eq, PartialEq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AttributeKey {
    #[display(fmt = "bold")]
    Bold,
    #[display(fmt = "italic")]
    Italic,
    #[display(fmt = "underline")]
    Underline,
    #[display(fmt = "strike_through")]
    StrikeThrough,
    #[display(fmt = "font")]
    Font,
    #[display(fmt = "size")]
    Size,
    #[display(fmt = "link")]
    Link,
    #[display(fmt = "color")]
    Color,
    #[display(fmt = "background")]
    Background,
    #[display(fmt = "ident")]
    Ident,
    #[display(fmt = "align")]
    Align,
    #[display(fmt = "code_block")]
    CodeBlock,
    #[display(fmt = "list")]
    List,
    #[display(fmt = "quote_block")]
    QuoteBlock,
    #[display(fmt = "width")]
    Width,
    #[display(fmt = "height")]
    Height,
    #[display(fmt = "style")]
    Style,
    #[display(fmt = "header")]
    Header,
    #[display(fmt = "left")]
    LeftAlignment,
    #[display(fmt = "center")]
    CenterAlignment,
    #[display(fmt = "right")]
    RightAlignment,
    #[display(fmt = "justify")]
    JustifyAlignment,
    #[display(fmt = "bullet")]
    Bullet,
    #[display(fmt = "ordered")]
    Ordered,
    #[display(fmt = "checked")]
    Checked,
    #[display(fmt = "unchecked")]
    UnChecked,
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum AttributeScope {
    Inline,
    Block,
    Embeds,
    Ignore,
}

#[derive(Debug, Clone)]
pub struct Attribute {
    pub key: AttributeKey,
    pub value: AttributeValue,
    pub scope: AttributeScope,
}

impl fmt::Display for Attribute {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let s = format!("{:?}:{} {:?}", self.key, self.value.as_ref(), self.scope);
        f.write_str(&s)
    }
}

impl std::convert::Into<Attributes> for Attribute {
    fn into(self) -> Attributes {
        let mut attributes = Attributes::new();
        attributes.add(self);
        attributes
    }
}

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

impl AttributeKey {
    pub fn remove(&self) -> Attribute { self.value(REMOVE_FLAG) }

    pub fn value<T: Into<AttributeValue>>(&self, value: T) -> Attribute {
        let key = self.clone();
        let value: AttributeValue = value.into();
        match self {
            AttributeKey::Bold
            | AttributeKey::Italic
            | AttributeKey::Underline
            | AttributeKey::StrikeThrough
            | AttributeKey::Link
            | AttributeKey::Color
            | AttributeKey::Background
            | AttributeKey::Font
            | AttributeKey::Size => Attribute {
                key,
                value,
                scope: AttributeScope::Inline,
            },

            AttributeKey::Header
            | AttributeKey::LeftAlignment
            | AttributeKey::CenterAlignment
            | AttributeKey::RightAlignment
            | AttributeKey::JustifyAlignment
            | AttributeKey::Ident
            | AttributeKey::Align
            | AttributeKey::CodeBlock
            | AttributeKey::List
            | AttributeKey::Bullet
            | AttributeKey::Ordered
            | AttributeKey::Checked
            | AttributeKey::UnChecked
            | AttributeKey::QuoteBlock => Attribute {
                key,
                value,
                scope: AttributeScope::Block,
            },

            AttributeKey::Width | AttributeKey::Height | AttributeKey::Style => Attribute {
                key,
                value,
                scope: AttributeScope::Ignore,
            },
        }
    }
}

impl std::convert::From<&usize> for AttributeValue {
    fn from(val: &usize) -> Self { AttributeValue(format!("{}", val)) }
}

impl std::convert::From<&str> for AttributeValue {
    fn from(val: &str) -> Self { AttributeValue(val.to_owned()) }
}

impl std::convert::From<bool> for AttributeValue {
    fn from(val: bool) -> Self {
        let val = match val {
            true => "true",
            false => "",
        };
        AttributeValue(val.to_owned())
    }
}
