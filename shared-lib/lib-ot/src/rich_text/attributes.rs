#![allow(non_snake_case)]
use crate::core::{Attributes, Operation, OperationTransformable};
use crate::{block_attribute, errors::OTError, ignore_attribute, inline_attribute, list_attribute};
use lazy_static::lazy_static;
use std::{
    collections::{HashMap, HashSet},
    fmt,
    fmt::Formatter,
    iter::FromIterator,
};
use strum_macros::Display;

pub type RichTextOperation = Operation<RichTextAttributes>;
impl RichTextOperation {
    pub fn contain_attribute(&self, attribute: &RichTextAttribute) -> bool {
        self.get_attributes().contains_key(&attribute.key)
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct RichTextAttributes {
    pub(crate) inner: HashMap<RichTextAttributeKey, RichTextAttributeValue>,
}

impl std::default::Default for RichTextAttributes {
    fn default() -> Self {
        Self {
            inner: HashMap::with_capacity(0),
        }
    }
}

impl fmt::Display for RichTextAttributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_fmt(format_args!("{:?}", self.inner))
    }
}

#[inline(always)]
pub fn plain_attributes() -> RichTextAttributes {
    RichTextAttributes::default()
}

impl RichTextAttributes {
    pub fn new() -> Self {
        RichTextAttributes { inner: HashMap::new() }
    }

    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    pub fn add(&mut self, attribute: RichTextAttribute) {
        let RichTextAttribute { key, value, scope: _ } = attribute;
        self.inner.insert(key, value);
    }

    pub fn insert(&mut self, key: RichTextAttributeKey, value: RichTextAttributeValue) {
        self.inner.insert(key, value);
    }

    pub fn delete(&mut self, key: &RichTextAttributeKey) {
        self.inner.insert(key.clone(), RichTextAttributeValue(None));
    }

    pub fn mark_all_as_removed_except(&mut self, attribute: Option<RichTextAttributeKey>) {
        match attribute {
            None => {
                self.inner.iter_mut().for_each(|(_k, v)| v.0 = None);
            }
            Some(attribute) => {
                self.inner.iter_mut().for_each(|(k, v)| {
                    if k != &attribute {
                        v.0 = None;
                    }
                });
            }
        }
    }

    pub fn remove(&mut self, key: RichTextAttributeKey) {
        self.inner.retain(|k, _| k != &key);
    }

    // pub fn block_attributes_except_header(attributes: &Attributes) -> Attributes
    // {     let mut new_attributes = Attributes::new();
    //     attributes.iter().for_each(|(k, v)| {
    //         if k != &AttributeKey::Header {
    //             new_attributes.insert(k.clone(), v.clone());
    //         }
    //     });
    //
    //     new_attributes
    // }

    // Update inner by constructing new attributes from the other if it's
    // not None and replace the key/value with self key/value.
    pub fn merge(&mut self, other: Option<RichTextAttributes>) {
        if other.is_none() {
            return;
        }

        let mut new_attributes = other.unwrap().inner;
        self.inner.iter().for_each(|(k, v)| {
            new_attributes.insert(k.clone(), v.clone());
        });
        self.inner = new_attributes;
    }
}

impl Attributes for RichTextAttributes {
    fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    fn remove_empty(&mut self) {
        self.inner.retain(|_, v| v.0.is_some());
    }

    fn extend_other(&mut self, other: Self) {
        self.inner.extend(other.inner);
    }
}

impl OperationTransformable for RichTextAttributes {
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        let mut attributes = self.clone();
        attributes.extend_other(other.clone());
        Ok(attributes)
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        let a = self
            .iter()
            .fold(RichTextAttributes::new(), |mut new_attributes, (k, v)| {
                if !other.contains_key(k) {
                    new_attributes.insert(k.clone(), v.clone());
                }
                new_attributes
            });

        let b = other
            .iter()
            .fold(RichTextAttributes::new(), |mut new_attributes, (k, v)| {
                if !self.contains_key(k) {
                    new_attributes.insert(k.clone(), v.clone());
                }
                new_attributes
            });

        Ok((a, b))
    }

    fn invert(&self, other: &Self) -> Self {
        let base_inverted = other.iter().fold(RichTextAttributes::new(), |mut attributes, (k, v)| {
            if other.get(k) != self.get(k) && self.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

        let inverted = self.iter().fold(base_inverted, |mut attributes, (k, _)| {
            if other.get(k) != self.get(k) && !other.contains_key(k) {
                attributes.delete(k);
            }
            attributes
        });

        inverted
    }
}

impl std::ops::Deref for RichTextAttributes {
    type Target = HashMap<RichTextAttributeKey, RichTextAttributeValue>;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for RichTextAttributes {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}

pub fn attributes_except_header(op: &RichTextOperation) -> RichTextAttributes {
    let mut attributes = op.get_attributes();
    attributes.remove(RichTextAttributeKey::Header);
    attributes
}

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
            }
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
    fn from(val: &usize) -> Self {
        RichTextAttributeValue::from(*val)
    }
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
    fn from(val: &str) -> Self {
        val.to_owned().into()
    }
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
    fn from(val: &bool) -> Self {
        RichTextAttributeValue::from(*val)
    }
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
