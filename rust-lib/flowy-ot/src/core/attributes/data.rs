use crate::core::{Attribute, Attributes};
use std::{collections::HashMap, fmt};

pub(crate) const REMOVE_FLAG: &'static str = "";
pub(crate) fn should_remove(s: &str) -> bool { s == REMOVE_FLAG }

#[derive(Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct AttributesData {
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    #[serde(flatten)]
    pub(crate) inner: HashMap<Attribute, String>,
}

impl AttributesData {
    pub fn new() -> Self {
        AttributesData {
            inner: HashMap::new(),
        }
    }
    pub fn is_empty(&self) -> bool {
        self.inner.values().filter(|v| !should_remove(v)).count() == 0
    }

    pub fn remove(&mut self, attribute: &Attribute) {
        self.inner.insert(attribute.clone(), REMOVE_FLAG.to_owned());
    }

    pub fn add(&mut self, attribute: Attribute) { self.inner.insert(attribute, "true".to_owned()); }

    pub fn extend(&mut self, other: Option<AttributesData>, prune: bool) {
        if other.is_none() {
            return;
        }

        if prune {
            let mut new_attributes = other.unwrap().inner;
            self.inner.iter().for_each(|(k, v)| {
                if should_remove(v) {
                    new_attributes.remove(k);
                } else {
                    new_attributes.insert(k.clone(), v.clone());
                }
            });
            self.inner = new_attributes;
        } else {
            self.inner.extend(other.unwrap().inner);
        }
    }
}

pub trait AttributesDataRule {
    fn apply_rule(&mut self);

    fn into_attributes(self) -> Attributes;
}
impl AttributesDataRule for AttributesData {
    fn apply_rule(&mut self) { self.inner.retain(|_, v| !should_remove(v)); }

    fn into_attributes(mut self) -> Attributes {
        self.apply_rule();

        if self.is_empty() {
            Attributes::Empty
        } else {
            Attributes::Custom(self)
        }
    }
}

pub trait AttributesRule {
    fn apply_rule(self) -> Attributes;
}

impl AttributesRule for Attributes {
    fn apply_rule(self) -> Attributes {
        match self {
            Attributes::Follow => self,
            Attributes::Custom(data) => data.into_attributes(),
            Attributes::Empty => self,
        }
    }
}
// impl std::convert::From<HashMap<String, String>> for AttributesData {
//     fn from(attributes: HashMap<String, String>) -> Self { AttributesData {
// inner: attributes } } }

impl std::ops::Deref for AttributesData {
    type Target = HashMap<Attribute, String>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for AttributesData {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}
