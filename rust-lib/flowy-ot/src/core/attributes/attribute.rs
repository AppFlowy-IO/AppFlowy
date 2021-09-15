#![allow(non_snake_case)]

use crate::{block_attribute, core::Attributes, ignore_attribute, inline_attribute};
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use std::{collections::HashSet, fmt, fmt::Formatter, iter::FromIterator};
use strum_macros::Display;
#[derive(Debug, Clone)]
pub struct Attribute {
    pub key: AttributeKey,
    pub value: AttributeValue,
    pub scope: AttributeScope,
}

impl Attribute {
    // inline
    inline_attribute!(Bold, bool);
    inline_attribute!(Italic, bool);
    inline_attribute!(Underline, bool);
    inline_attribute!(StrikeThrough, bool);
    inline_attribute!(Link, &str);
    inline_attribute!(Color, String);
    inline_attribute!(Font, usize);
    inline_attribute!(Size, usize);
    inline_attribute!(Background, String);

    // block
    block_attribute!(Header, usize);
    block_attribute!(Indent, usize);
    block_attribute!(Align, String);
    block_attribute!(List, String);
    block_attribute!(CodeBlock, bool);
    block_attribute!(QuoteBlock, bool);

    // ignore
    ignore_attribute!(Width, usize);
    ignore_attribute!(Height, usize);
}

impl fmt::Display for Attribute {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let s = format!("{:?}:{:?} {:?}", self.key, self.value.0, self.scope);
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
// serde.rs/variant-attrs.html
// #[serde(rename_all = "snake_case")]
pub enum AttributeKey {
    #[serde(rename = "bold")]
    Bold,
    #[serde(rename = "italic")]
    Italic,
    #[serde(rename = "underline")]
    Underline,
    #[serde(rename = "strikethrough")]
    StrikeThrough,
    #[serde(rename = "font")]
    Font,
    #[serde(rename = "size")]
    Size,
    #[serde(rename = "link")]
    Link,
    #[serde(rename = "color")]
    Color,
    #[serde(rename = "background")]
    Background,
    #[serde(rename = "indent")]
    Indent,
    #[serde(rename = "align")]
    Align,
    #[serde(rename = "code_block")]
    CodeBlock,
    #[serde(rename = "list")]
    List,
    #[serde(rename = "quote_block")]
    QuoteBlock,
    #[serde(rename = "width")]
    Width,
    #[serde(rename = "height")]
    Height,
    #[serde(rename = "header")]
    Header,
}

// pub trait AttributeValueData<'a>: Serialize + Deserialize<'a> {}
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AttributeValue(pub(crate) Option<String>);

impl std::convert::From<&usize> for AttributeValue {
    fn from(val: &usize) -> Self { AttributeValue::from(*val) }
}

impl std::convert::From<usize> for AttributeValue {
    fn from(val: usize) -> Self {
        if val > (0 as usize) {
            AttributeValue(Some(format!("{}", val)))
        } else {
            AttributeValue(None)
        }
    }
}

impl std::convert::From<&str> for AttributeValue {
    fn from(val: &str) -> Self { AttributeValue(Some(val.to_owned())) }
}

impl std::convert::From<String> for AttributeValue {
    fn from(val: String) -> Self {
        if val.is_empty() {
            AttributeValue(None)
        } else {
            AttributeValue(Some(val))
        }
    }
}

impl std::convert::From<&bool> for AttributeValue {
    fn from(val: &bool) -> Self { AttributeValue::from(*val) }
}

impl std::convert::From<bool> for AttributeValue {
    fn from(val: bool) -> Self {
        let val = match val {
            true => Some("true".to_owned()),
            false => None,
        };
        AttributeValue(val)
    }
}

pub fn is_block_except_header(k: &AttributeKey) -> bool {
    if k == &AttributeKey::Header {
        return false;
    }
    BLOCK_KEYS.contains(k)
}

lazy_static! {
    static ref BLOCK_KEYS: HashSet<AttributeKey> = HashSet::from_iter(vec![
        AttributeKey::Header,
        AttributeKey::Indent,
        AttributeKey::Align,
        AttributeKey::CodeBlock,
        AttributeKey::List,
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
    static ref INGORE_KEYS: HashSet<AttributeKey> = HashSet::from_iter(vec![AttributeKey::Width, AttributeKey::Height,]);
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum AttributeScope {
    Inline,
    Block,
    Embeds,
    Ignore,
}
