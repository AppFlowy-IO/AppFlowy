use crate::core::{Attributes, REMOVE_FLAG};
use derive_more::Display;
use std::{fmt, fmt::Formatter};

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
    #[display(fmt = "header")]
    Header,
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
    #[display(fmt = "h1")]
    H1,
    #[display(fmt = "h2")]
    H2,
    #[display(fmt = "h3")]
    H3,
    #[display(fmt = "h4")]
    H4,
    #[display(fmt = "h5")]
    H5,
    #[display(fmt = "h6")]
    H6,
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

#[derive(Debug)]
pub enum AttributeScope {
    Inline,
    Block,
    Embeds,
    Ignore,
}

#[derive(Debug)]
pub struct Attribute {
    pub key: AttributeKey,
    pub value: String,
    pub scope: AttributeScope,
}

impl fmt::Display for Attribute {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let s = format!("{:?}:{} {:?}", self.key, self.value, self.scope);
        f.write_str(&s)
    }
}

pub struct AttrsBuilder {
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

impl AttrsBuilder {
    pub fn new() -> Self {
        Self {
            inner: Attributes::default(),
        }
    }

    pub fn add(mut self, attribute: Attribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn insert<T: Into<String>>(mut self, key: AttributeKey, value: T) -> Self {
        self.inner.add(key.with_value(value));
        self
    }

    pub fn remove<T: Into<String>>(mut self, key: AttributeKey) -> Self {
        self.inner.add(key.with_value(REMOVE_FLAG));
        self
    }

    impl_bool_attribute!(bold, AttributeKey::Bold);
    impl_bool_attribute!(italic, AttributeKey::Italic);
    impl_bool_attribute!(underline, AttributeKey::Underline);
    impl_bool_attribute!(strike_through, AttributeKey::StrikeThrough);

    pub fn build(self) -> Attributes { self.inner }
}

impl AttributeKey {
    pub fn with_value<T: Into<String>>(&self, value: T) -> Attribute {
        let key = self.clone();
        let value: String = value.into();
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
            | AttributeKey::H1
            | AttributeKey::H2
            | AttributeKey::H3
            | AttributeKey::H4
            | AttributeKey::H5
            | AttributeKey::H6
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
