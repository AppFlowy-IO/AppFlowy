#![allow(non_snake_case)]

use crate::{block_attribute, core::RichTextAttributes, ignore_attribute, inline_attribute, list_attribute};
use lazy_static::lazy_static;

use std::{collections::HashSet, fmt, fmt::Formatter, iter::FromIterator};
use strum_macros::Display;

#[derive(Debug, Clone)]
pub struct RichTextAttribute {
    pub key: RichTextAttributeKey,
    pub value: RichTextAttributeValue,
    pub scope: AttributeScope,
}

impl RichTextAttribute {
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
    inline_attribute!(InlineCode, bool);

    // block
    block_attribute!(Header, usize);
    block_attribute!(Indent, usize);
    block_attribute!(Align, String);
    block_attribute!(List, &str);
    block_attribute!(CodeBlock, bool);
    block_attribute!(BlockQuote, bool);

    // ignore
    ignore_attribute!(Width, usize);
    ignore_attribute!(Height, usize);

    // List extension
    list_attribute!(Bullet, "bullet");
    list_attribute!(Ordered, "ordered");
    list_attribute!(Checked, "checked");
    list_attribute!(UnChecked, "unchecked");

    pub fn to_json(&self) -> String {
        match serde_json::to_string(self) {
            Ok(json) => json,
            Err(e) => {
                log::error!("Attribute serialize to str failed: {}", e);
                "".to_owned()
            },
        }
    }
}

impl fmt::Display for RichTextAttribute {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let s = format!("{:?}:{:?} {:?}", self.key, self.value.0, self.scope);
        f.write_str(&s)
    }
}

impl std::convert::From<RichTextAttribute> for RichTextAttributes {
    fn from(attr: RichTextAttribute) -> Self {
        let mut attributes = RichTextAttributes::new();
        attributes.add(attr);
        attributes
    }
}

#[derive(Clone, Debug, Display, Hash, Eq, PartialEq, serde::Serialize, serde::Deserialize)]
// serde.rs/variant-attrs.html
// #[serde(rename_all = "snake_case")]
pub enum RichTextAttributeKey {
    #[serde(rename = "bold")]
    Bold,
    #[serde(rename = "italic")]
    Italic,
    #[serde(rename = "underline")]
    Underline,
    #[serde(rename = "strike")]
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
    #[serde(rename = "code")]
    InlineCode,
    #[serde(rename = "list")]
    List,
    #[serde(rename = "blockquote")]
    BlockQuote,
    #[serde(rename = "width")]
    Width,
    #[serde(rename = "height")]
    Height,
    #[serde(rename = "header")]
    Header,
}

// pub trait AttributeValueData<'a>: Serialize + Deserialize<'a> {}
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct RichTextAttributeValue(pub Option<String>);

impl std::convert::From<&usize> for RichTextAttributeValue {
    fn from(val: &usize) -> Self { RichTextAttributeValue::from(*val) }
}

impl std::convert::From<usize> for RichTextAttributeValue {
    fn from(val: usize) -> Self {
        if val > 0_usize {
            RichTextAttributeValue(Some(format!("{}", val)))
        } else {
            RichTextAttributeValue(None)
        }
    }
}

impl std::convert::From<&str> for RichTextAttributeValue {
    fn from(val: &str) -> Self { val.to_owned().into() }
}

impl std::convert::From<String> for RichTextAttributeValue {
    fn from(val: String) -> Self {
        if val.is_empty() {
            RichTextAttributeValue(None)
        } else {
            RichTextAttributeValue(Some(val))
        }
    }
}

impl std::convert::From<&bool> for RichTextAttributeValue {
    fn from(val: &bool) -> Self { RichTextAttributeValue::from(*val) }
}

impl std::convert::From<bool> for RichTextAttributeValue {
    fn from(val: bool) -> Self {
        let val = match val {
            true => Some("true".to_owned()),
            false => None,
        };
        RichTextAttributeValue(val)
    }
}

pub fn is_block_except_header(k: &RichTextAttributeKey) -> bool {
    if k == &RichTextAttributeKey::Header {
        return false;
    }
    BLOCK_KEYS.contains(k)
}

lazy_static! {
    static ref BLOCK_KEYS: HashSet<RichTextAttributeKey> = HashSet::from_iter(vec![
        RichTextAttributeKey::Header,
        RichTextAttributeKey::Indent,
        RichTextAttributeKey::Align,
        RichTextAttributeKey::CodeBlock,
        RichTextAttributeKey::List,
        RichTextAttributeKey::BlockQuote,
    ]);
    static ref INLINE_KEYS: HashSet<RichTextAttributeKey> = HashSet::from_iter(vec![
        RichTextAttributeKey::Bold,
        RichTextAttributeKey::Italic,
        RichTextAttributeKey::Underline,
        RichTextAttributeKey::StrikeThrough,
        RichTextAttributeKey::Link,
        RichTextAttributeKey::Color,
        RichTextAttributeKey::Font,
        RichTextAttributeKey::Size,
        RichTextAttributeKey::Background,
        RichTextAttributeKey::InlineCode,
    ]);
    static ref INGORE_KEYS: HashSet<RichTextAttributeKey> =
        HashSet::from_iter(vec![RichTextAttributeKey::Width, RichTextAttributeKey::Height,]);
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum AttributeScope {
    Inline,
    Block,
    Embeds,
    Ignore,
}
