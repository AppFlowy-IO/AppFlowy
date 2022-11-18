#![allow(non_snake_case)]
use crate::core::{AttributeEntry, AttributeHashMap, AttributeKey};
use crate::text_delta::DeltaTextOperation;
use crate::{inline_attribute_entry, inline_list_attribute_entry};
use lazy_static::lazy_static;
use std::str::FromStr;
use std::{collections::HashSet, iter::FromIterator};
use strum_macros::{AsRefStr, Display, EnumString};

#[inline(always)]
pub fn empty_attributes() -> AttributeHashMap {
    AttributeHashMap::default()
}

pub fn attributes_except_header(op: &DeltaTextOperation) -> AttributeHashMap {
    let mut attributes = op.get_attributes();
    attributes.remove_key(BuildInTextAttributeKey::Header);
    attributes
}

#[derive(Debug, Clone)]
pub struct BuildInTextAttribute();

impl BuildInTextAttribute {
    inline_attribute_entry!(Bold, bool);
    inline_attribute_entry!(Italic, bool);
    inline_attribute_entry!(Underline, bool);
    inline_attribute_entry!(StrikeThrough, bool);
    inline_attribute_entry!(Link, &str);
    inline_attribute_entry!(Color, String);
    inline_attribute_entry!(Font, usize);
    inline_attribute_entry!(Size, usize);
    inline_attribute_entry!(Background, String);
    inline_attribute_entry!(InlineCode, bool);

    inline_attribute_entry!(Header, usize);
    inline_attribute_entry!(Indent, usize);
    inline_attribute_entry!(Align, String);
    inline_attribute_entry!(List, &str);
    inline_attribute_entry!(CodeBlock, bool);
    inline_attribute_entry!(BlockQuote, bool);

    inline_attribute_entry!(Width, usize);
    inline_attribute_entry!(Height, usize);

    // List extension
    inline_list_attribute_entry!(Bullet, "bullet");
    inline_list_attribute_entry!(Ordered, "ordered");
    inline_list_attribute_entry!(Checked, "checked");
    inline_list_attribute_entry!(UnChecked, "unchecked");
}

#[derive(Clone, Debug, Display, Hash, Eq, PartialEq, serde::Serialize, serde::Deserialize, AsRefStr, EnumString)]
#[strum(serialize_all = "snake_case")]
pub enum BuildInTextAttributeKey {
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

pub fn is_block(k: &AttributeKey) -> bool {
    if let Ok(key) = BuildInTextAttributeKey::from_str(k) {
        BLOCK_KEYS.contains(&key)
    } else {
        false
    }
}

pub fn is_inline(k: &AttributeKey) -> bool {
    if let Ok(key) = BuildInTextAttributeKey::from_str(k) {
        INLINE_KEYS.contains(&key)
    } else {
        false
    }
}

lazy_static! {
    static ref BLOCK_KEYS: HashSet<BuildInTextAttributeKey> = HashSet::from_iter(vec![
        BuildInTextAttributeKey::Header,
        BuildInTextAttributeKey::Indent,
        BuildInTextAttributeKey::Align,
        BuildInTextAttributeKey::CodeBlock,
        BuildInTextAttributeKey::List,
        BuildInTextAttributeKey::BlockQuote,
    ]);
    static ref INLINE_KEYS: HashSet<BuildInTextAttributeKey> = HashSet::from_iter(vec![
        BuildInTextAttributeKey::Bold,
        BuildInTextAttributeKey::Italic,
        BuildInTextAttributeKey::Underline,
        BuildInTextAttributeKey::StrikeThrough,
        BuildInTextAttributeKey::Link,
        BuildInTextAttributeKey::Color,
        BuildInTextAttributeKey::Font,
        BuildInTextAttributeKey::Size,
        BuildInTextAttributeKey::Background,
        BuildInTextAttributeKey::InlineCode,
    ]);
    static ref INGORE_KEYS: HashSet<BuildInTextAttributeKey> =
        HashSet::from_iter(vec![BuildInTextAttributeKey::Width, BuildInTextAttributeKey::Height,]);
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum AttributeScope {
    Inline,
    Block,
    Embeds,
    Ignore,
}
