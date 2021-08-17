use crate::core::{Attributes, REMOVE_FLAG};
use derive_more::Display;
use lazy_static::lazy_static;
use std::{collections::HashSet, fmt, fmt::Formatter, iter::FromIterator};

lazy_static! {
    static ref BLOCK_KEYS: HashSet<AttributeKey> = HashSet::from_iter(vec![
        AttributeKey::Header,
        AttributeKey::LeftAlignment,
        AttributeKey::CenterAlignment,
        AttributeKey::RightAlignment,
        AttributeKey::JustifyAlignment,
        AttributeKey::Indent,
        AttributeKey::Align,
        AttributeKey::CodeBlock,
        AttributeKey::List,
        AttributeKey::Bullet,
        AttributeKey::Ordered,
        AttributeKey::Checked,
        AttributeKey::UnChecked,
        AttributeKey::QuoteBlock,
    ]);
    static ref INLINE_KEYS: HashSet<AttributeKey> = HashSet::from_iter(vec![
        AttributeKey::Bold,
        AttributeKey::Italic,
        AttributeKey::Underline,
        AttributeKey::StrikeThrough,
        AttributeKey::Link,
        AttributeKey::Color,
        AttributeKey::Font,
        AttributeKey::Size,
        AttributeKey::Background,
    ]);
    static ref INGORE_KEYS: HashSet<AttributeKey> = HashSet::from_iter(vec![
        AttributeKey::Width,
        AttributeKey::Height,
        AttributeKey::Style,
    ]);
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
    #[display(fmt = "indent")]
    Indent,
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

impl AttributeKey {
    pub fn remove(&self) -> Attribute { self.value(REMOVE_FLAG) }

    pub fn value<T: Into<AttributeValue>>(&self, value: T) -> Attribute {
        let key = self.clone();
        let value: AttributeValue = value.into();
        if INLINE_KEYS.contains(self) {
            return Attribute {
                key,
                value,
                scope: AttributeScope::Inline,
            };
        }

        if BLOCK_KEYS.contains(self) {
            return Attribute {
                key,
                value,
                scope: AttributeScope::Block,
            };
        }

        Attribute {
            key,
            value,
            scope: AttributeScope::Ignore,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AttributeValue(pub(crate) String);

impl AsRef<str> for AttributeValue {
    fn as_ref(&self) -> &str { &self.0 }
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

pub fn is_block_except_header(k: &AttributeKey) -> bool {
    if k == &AttributeKey::Header {
        return false;
    }
    BLOCK_KEYS.contains(k)
}
