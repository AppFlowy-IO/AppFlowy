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

impl fmt::Display for AttributesData {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_fmt(format_args!("{:?}", self.inner))
    }
}

impl AttributesData {
    pub fn new() -> Self {
        AttributesData {
            inner: HashMap::new(),
        }
    }

    pub fn is_empty(&self) -> bool { self.inner.is_empty() }

    pub fn add(&mut self, attribute: Attribute) { self.inner.insert(attribute, "true".to_owned()); }

    pub fn remove(&mut self, attribute: &Attribute) {
        self.inner.insert(attribute.clone(), REMOVE_FLAG.to_owned());
    }

    // Remove the key if its value is empty. e.g. { bold: "" }
    pub fn remove_empty_value(&mut self) { self.inner.retain(|_, v| !should_remove(v)); }

    pub fn extend(&mut self, other: Option<AttributesData>) {
        if other.is_none() {
            return;
        }
        self.inner.extend(other.unwrap().inner);
    }

    // Update self attributes by constructing new attributes from the other if it's
    // not None and replace the key/value with self key/value.
    pub fn merge(&mut self, other: Option<AttributesData>) {
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

impl std::ops::Deref for AttributesData {
    type Target = HashMap<Attribute, String>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for AttributesData {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

impl std::convert::Into<Attributes> for AttributesData {
    fn into(self) -> Attributes { Attributes::Custom(self) }
}
