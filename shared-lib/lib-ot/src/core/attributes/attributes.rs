use crate::{
    core::{
        Attributes,
        OperationTransformable,
        RichTextAttribute,
        RichTextAttributeKey,
        RichTextAttributeValue,
        RichTextOperation,
    },
    errors::OTError,
};
use std::{collections::HashMap, fmt};

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
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_fmt(format_args!("{:?}", self.inner)) }
}

pub fn plain_attributes() -> RichTextAttributes { RichTextAttributes::default() }

impl RichTextAttributes {
    pub fn new() -> Self { RichTextAttributes { inner: HashMap::new() } }

    pub fn is_empty(&self) -> bool { self.inner.is_empty() }

    pub fn add(&mut self, attribute: RichTextAttribute) {
        let RichTextAttribute { key, value, scope: _ } = attribute;
        self.inner.insert(key, value);
    }

    pub fn add_kv(&mut self, key: RichTextAttributeKey, value: RichTextAttributeValue) {
        self.inner.insert(key, value);
    }

    pub fn delete(&mut self, key: &RichTextAttributeKey) {
        self.inner.insert(key.clone(), RichTextAttributeValue(None));
    }

    pub fn mark_all_as_removed_except(&mut self, attribute: Option<RichTextAttributeKey>) {
        match attribute {
            None => {
                self.inner.iter_mut().for_each(|(_k, v)| v.0 = None);
            },
            Some(attribute) => {
                self.inner.iter_mut().for_each(|(k, v)| {
                    if k != &attribute {
                        v.0 = None;
                    }
                });
            },
        }
    }

    pub fn remove(&mut self, key: RichTextAttributeKey) { self.inner.retain(|k, _| k != &key); }

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
    fn is_empty(&self) -> bool { self.inner.is_empty() }

    fn remove_empty(&mut self) { self.inner.retain(|_, v| v.0.is_some()); }

    fn extend_other(&mut self, other: Self) { self.inner.extend(other.inner); }
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

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for RichTextAttributes {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

pub fn attributes_except_header(op: &RichTextOperation) -> RichTextAttributes {
    let mut attributes = op.get_attributes();
    attributes.remove(RichTextAttributeKey::Header);
    attributes
}
