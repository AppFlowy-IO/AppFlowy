use crate::core::{OperationAttributes, OperationTransform};
use crate::errors::OTError;
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::fmt::Display;

#[derive(Debug, Clone)]
pub struct AttributeEntry {
    pub key: AttributeKey,
    pub value: AttributeValue,
}

impl AttributeEntry {
    pub fn new<K: Into<AttributeKey>, V: Into<AttributeValue>>(key: K, value: V) -> Self {
        Self {
            key: key.into(),
            value: value.into(),
        }
    }

    pub fn clear(&mut self) {
        self.value.ty = None;
        self.value.value = None;
    }
}

impl std::convert::From<AttributeEntry> for AttributeHashMap {
    fn from(entry: AttributeEntry) -> Self {
        let mut attributes = AttributeHashMap::new();
        attributes.insert_entry(entry);
        attributes
    }
}

#[derive(Default, Clone, Serialize, Deserialize, Eq, PartialEq, Debug)]
pub struct AttributeHashMap(IndexMap<AttributeKey, AttributeValue>);

impl std::ops::Deref for AttributeHashMap {
    type Target = IndexMap<AttributeKey, AttributeValue>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for AttributeHashMap {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl AttributeHashMap {
    pub fn new() -> AttributeHashMap {
        AttributeHashMap(IndexMap::new())
    }

    pub fn into_inner(self) -> IndexMap<AttributeKey, AttributeValue> {
        self.0
    }

    // pub fn from_value(attribute_map: HashMap<AttributeKey, AttributeValue>) -> Self {
    //     Self(attribute_map)
    // }

    pub fn insert<K: ToString, V: Into<AttributeValue>>(&mut self, key: K, value: V) {
        self.0.insert(key.to_string(), value.into());
    }

    pub fn insert_entry(&mut self, entry: AttributeEntry) {
        self.insert(entry.key, entry.value)
    }

    /// Set the key's value to None
    pub fn remove_value<K: AsRef<str>>(&mut self, key: K) {
        // if let Some(mut_value) = self.0.get_mut(key.as_ref()) {
        //     mut_value.value = None;
        // }
        self.insert(key.as_ref().to_string(), AttributeValue::none());
    }

    /// Set all key's value to None
    pub fn remove_all_value(&mut self) {
        self.0.iter_mut().for_each(|(_, v)| {
            *v = AttributeValue::none();
        })
    }

    pub fn retain_values(&mut self, retain_keys: &[&str]) {
        self.0.iter_mut().for_each(|(k, v)| {
            if !retain_keys.contains(&k.as_str()) {
                *v = AttributeValue::none();
            }
        })
    }

    pub fn remove_key<K: AsRef<str>>(&mut self, key: K) {
        self.0.remove(key.as_ref());
    }

    /// Create a new key/value map by constructing new attributes from the other
    /// if it's not None and replace the key/value with self key/value.
    pub fn merge(&mut self, other: Option<AttributeHashMap>) {
        if other.is_none() {
            return;
        }

        let mut new_attributes = other.unwrap().0;
        self.0.iter().for_each(|(k, v)| {
            new_attributes.insert(k.clone(), v.clone());
        });
        self.0 = new_attributes;
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    pub fn to_json(&self) -> Result<String, OTError> {
        serde_json::to_string(self).map_err(|err| OTError::serde().context(err))
    }
}

impl Display for AttributeHashMap {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for (key, value) in self.0.iter() {
            f.write_str(&format!("{:?}:{:?}", key, value))?;
        }
        Ok(())
    }
}

impl OperationAttributes for AttributeHashMap {
    fn is_empty(&self) -> bool {
        self.is_empty()
    }

    fn remove(&mut self) {
        self.retain(|_, v| v.value.is_some());
    }

    fn extend(&mut self, other: Self) {
        self.0.extend(other.0);
    }
}

impl OperationTransform for AttributeHashMap {
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        let mut attributes = self.clone();
        attributes.0.extend(other.clone().0);
        Ok(attributes)
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        let a = self.iter().fold(AttributeHashMap::new(), |mut new_attributes, (k, v)| {
            if !other.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        });

        let b = other
            .iter()
            .fold(AttributeHashMap::new(), |mut new_attributes, (k, v)| {
                if !self.contains_key(k) {
                    new_attributes.insert(k.clone(), v.clone());
                }
                new_attributes
            });

        Ok((a, b))
    }

    fn invert(&self, other: &Self) -> Self {
        let base_inverted = other.iter().fold(AttributeHashMap::new(), |mut attributes, (k, v)| {
            if other.get(k) != self.get(k) && self.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

        self.iter().fold(base_inverted, |mut attributes, (k, _)| {
            if other.get(k) != self.get(k) && !other.contains_key(k) {
                attributes.remove_value(k);
            }
            attributes
        })
    }
}

pub type AttributeKey = String;

#[derive(Eq, PartialEq, Hash, Debug, Clone)]
pub enum ValueType {
    IntType = 0,
    FloatType = 1,
    StrType = 2,
    BoolType = 3,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AttributeValue {
    pub ty: Option<ValueType>,
    pub value: Option<String>,
}

impl AttributeValue {
    pub fn none() -> Self {
        Self { ty: None, value: None }
    }
    pub fn from_int(val: i64) -> Self {
        Self {
            ty: Some(ValueType::IntType),
            value: Some(val.to_string()),
        }
    }

    pub fn from_float(val: f64) -> Self {
        Self {
            ty: Some(ValueType::FloatType),
            value: Some(val.to_string()),
        }
    }

    pub fn from_bool(val: bool) -> Self {
        // let value = if val { Some(val.to_string()) } else { None };
        Self {
            ty: Some(ValueType::BoolType),
            value: Some(val.to_string()),
        }
    }
    pub fn from_string(s: &str) -> Self {
        let value = if s.is_empty() { None } else { Some(s.to_string()) };
        Self {
            ty: Some(ValueType::StrType),
            value,
        }
    }

    pub fn int_value(&self) -> Option<i64> {
        let value = self.value.as_ref()?;
        Some(value.parse::<i64>().unwrap_or(0))
    }

    pub fn bool_value(&self) -> Option<bool> {
        let value = self.value.as_ref()?;
        Some(value.parse::<bool>().unwrap_or(false))
    }

    pub fn str_value(&self) -> Option<String> {
        self.value.clone()
    }

    pub fn float_value(&self) -> Option<f64> {
        let value = self.value.as_ref()?;
        Some(value.parse::<f64>().unwrap_or(0.0))
    }
}

impl std::convert::From<bool> for AttributeValue {
    fn from(value: bool) -> Self {
        AttributeValue::from_bool(value)
    }
}

impl std::convert::From<usize> for AttributeValue {
    fn from(value: usize) -> Self {
        AttributeValue::from_int(value as i64)
    }
}

impl std::convert::From<&str> for AttributeValue {
    fn from(value: &str) -> Self {
        AttributeValue::from_string(value)
    }
}

impl std::convert::From<String> for AttributeValue {
    fn from(value: String) -> Self {
        AttributeValue::from_string(&value)
    }
}

impl std::convert::From<f64> for AttributeValue {
    fn from(value: f64) -> Self {
        AttributeValue::from_float(value)
    }
}

impl std::convert::From<i64> for AttributeValue {
    fn from(value: i64) -> Self {
        AttributeValue::from_int(value)
    }
}

impl std::convert::From<i32> for AttributeValue {
    fn from(value: i32) -> Self {
        AttributeValue::from_int(value as i64)
    }
}

#[derive(Default)]
pub struct AttributeBuilder {
    attributes: AttributeHashMap,
}

impl AttributeBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert<K: ToString, V: Into<AttributeValue>>(mut self, key: K, value: V) -> Self {
        self.attributes.insert(key, value);
        self
    }

    pub fn insert_entry(mut self, entry: AttributeEntry) -> Self {
        self.attributes.insert_entry(entry);
        self
    }

    pub fn delete<K: AsRef<str>>(mut self, key: K) -> Self {
        self.attributes.remove_value(key);
        self
    }

    pub fn build(self) -> AttributeHashMap {
        self.attributes
    }
}
