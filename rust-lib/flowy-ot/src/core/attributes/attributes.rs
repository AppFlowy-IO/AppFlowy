use crate::{
    core::{Attribute, AttributeKey, AttributeValue, Operation, OperationTransformable},
    errors::OTError,
};
use std::{collections::HashMap, fmt};

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct Attributes {
    pub(crate) inner: HashMap<AttributeKey, AttributeValue>,
}

impl std::default::Default for Attributes {
    fn default() -> Self {
        Self {
            inner: HashMap::with_capacity(0),
        }
    }
}

impl fmt::Display for Attributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_fmt(format_args!("{:?}", self.inner)) }
}

pub fn plain_attributes() -> Attributes { Attributes::default() }

impl Attributes {
    pub fn new() -> Self { Attributes { inner: HashMap::new() } }

    pub fn is_empty(&self) -> bool { self.inner.is_empty() }

    pub fn add(&mut self, attribute: Attribute) {
        let Attribute { key, value, scope: _ } = attribute;
        self.inner.insert(key, value);
    }

    pub fn add_kv(&mut self, key: AttributeKey, value: AttributeValue) { self.inner.insert(key, value); }

    pub fn delete(&mut self, key: &AttributeKey) { self.inner.insert(key.clone(), AttributeValue(None)); }

    pub fn mark_all_as_removed_except(&mut self, attribute: Option<AttributeKey>) {
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

    pub fn remove(&mut self, key: AttributeKey) { self.inner.retain(|k, _| k != &key); }

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

    // Remove the empty attribute which value is None.
    pub fn remove_empty(&mut self) { self.inner.retain(|_, v| v.0.is_some()); }

    pub fn extend(&mut self, other: Attributes) { self.inner.extend(other.inner); }

    // Update inner by constructing new attributes from the other if it's
    // not None and replace the key/value with self key/value.
    pub fn merge(&mut self, other: Option<Attributes>) {
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

impl OperationTransformable for Attributes {
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        let mut attributes = self.clone();
        attributes.extend(other.clone());
        Ok(attributes)
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        let a = self.iter().fold(Attributes::new(), |mut new_attributes, (k, v)| {
            if !other.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        });

        let b = other.iter().fold(Attributes::new(), |mut new_attributes, (k, v)| {
            if !self.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        });

        Ok((a, b))
    }

    fn invert(&self, other: &Self) -> Self {
        let base_inverted = other.iter().fold(Attributes::new(), |mut attributes, (k, v)| {
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

        return inverted;
    }
}

impl std::ops::Deref for Attributes {
    type Target = HashMap<AttributeKey, AttributeValue>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for Attributes {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

pub fn attributes_except_header(op: &Operation) -> Attributes {
    let mut attributes = op.get_attributes();
    attributes.remove(AttributeKey::Header);
    attributes
}
