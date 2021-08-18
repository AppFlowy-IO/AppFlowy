use crate::core::{Attribute, AttributeKey, AttributeValue, Operation};
use std::{collections::HashMap, fmt};

pub const REMOVE_FLAG: &'static str = "";
pub(crate) fn should_remove(val: &AttributeValue) -> bool { val.0 == REMOVE_FLAG }

#[derive(Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Attributes {
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    #[serde(flatten)]
    pub(crate) inner: HashMap<AttributeKey, AttributeValue>,
}

impl fmt::Display for Attributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_fmt(format_args!("{:?}", self.inner))
    }
}

impl Attributes {
    pub fn new() -> Self {
        Attributes {
            inner: HashMap::new(),
        }
    }

    pub fn empty() -> Self { Self::default() }

    pub fn is_empty(&self) -> bool { self.inner.is_empty() }

    pub fn add(&mut self, attribute: Attribute) {
        let Attribute {
            key,
            value,
            scope: _,
        } = attribute;
        self.inner.insert(key, value);
    }

    pub fn mark_as_removed(&mut self, key: &AttributeKey) {
        let value: AttributeValue = REMOVE_FLAG.into();
        self.inner.insert(key.clone(), value);
    }

    pub fn mark_all_as_removed_except(&mut self, attribute: Option<AttributeKey>) {
        match attribute {
            None => {
                self.inner
                    .iter_mut()
                    .for_each(|(_k, v)| v.0 = REMOVE_FLAG.into());
            },
            Some(attribute) => {
                self.inner.iter_mut().for_each(|(k, v)| {
                    if k != &attribute {
                        v.0 = REMOVE_FLAG.into();
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

    // Remove the empty attribute which value is empty. e.g. {bold: ""}.
    pub fn remove_empty(&mut self) { self.inner.retain(|_, v| !should_remove(v)); }

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

impl std::ops::Deref for Attributes {
    type Target = HashMap<AttributeKey, AttributeValue>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for Attributes {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

pub(crate) fn attributes_from(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => Some(operation.get_attributes()),
    }
}

pub fn compose_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    if left.is_none() && right.is_none() {
        return Attributes::default();
    }
    let attr_left = attributes_from(left);
    let attr_right = attributes_from(right);

    if attr_left.is_none() {
        return attr_right.unwrap();
    }

    if attr_right.is_none() {
        return attr_left.unwrap();
    }

    let left = attr_left.unwrap();
    let right = attr_right.unwrap();
    log::trace!("compose attributes: a: {:?}, b: {:?}", left, right);
    let attr = merge_attributes(left, right);
    log::trace!("compose attributes result: {:?}", attr);
    attr
}

pub fn compose_attributes(left: Attributes, right: Attributes) -> Attributes {
    log::trace!("compose attributes: a: {:?}, b: {:?}", left, right);
    let attr = merge_attributes(left, right);
    log::trace!("compose attributes result: {:?}", attr);
    attr
}

pub fn transform_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    let attr_l = attributes_from(left);
    let attr_r = attributes_from(right);

    if attr_l.is_none() {
        if attr_r.is_none() {
            return Attributes::default();
        }

        return attr_r.unwrap();
    }

    let left = attr_l.unwrap();
    let right = attr_r.unwrap();
    left.iter()
        .fold(Attributes::new(), |mut new_attributes, (k, v)| {
            if !right.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        })
}

pub fn invert_attributes(attr: Attributes, base: Attributes) -> Attributes {
    let base_inverted = base
        .iter()
        .fold(Attributes::new(), |mut attributes, (k, v)| {
            if base.get(k) != attr.get(k) && attr.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

    let inverted = attr.iter().fold(base_inverted, |mut attributes, (k, _)| {
        if base.get(k) != attr.get(k) && !base.contains_key(k) {
            attributes.mark_as_removed(k);
        }
        attributes
    });

    return inverted;
}

pub fn merge_attributes(mut attributes: Attributes, other: Attributes) -> Attributes {
    attributes.extend(other);
    attributes
}

pub fn attributes_except_header(op: &Operation) -> Attributes {
    let mut attributes = op.get_attributes();
    attributes.remove(AttributeKey::Header);
    attributes
}
