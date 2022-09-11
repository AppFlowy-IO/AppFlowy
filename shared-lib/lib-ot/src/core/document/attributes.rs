use crate::core::OperationTransform;
use crate::errors::OTError;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::collections::HashMap;
pub type AttributeMap = HashMap<AttributeKey, AttributeValue>;

#[derive(Default, Clone, Serialize, Deserialize, Eq, PartialEq, Debug)]
pub struct NodeAttributes(AttributeMap);

impl std::ops::Deref for NodeAttributes {
    type Target = AttributeMap;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for NodeAttributes {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl NodeAttributes {
    pub fn new() -> NodeAttributes {
        NodeAttributes(HashMap::new())
    }

    pub fn from_value(attribute_map: AttributeMap) -> Self {
        Self(attribute_map)
    }

    pub fn insert<K: ToString, V: Into<AttributeValue>>(&mut self, key: K, value: V) {
        self.0.insert(key.to_string(), value.into());
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    pub fn delete<K: ToString>(&mut self, key: K) {
        self.insert(key.to_string(), AttributeValue::empty());
    }
}

impl OperationTransform for NodeAttributes {
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
        let a = self.iter().fold(NodeAttributes::new(), |mut new_attributes, (k, v)| {
            if !other.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        });

        let b = other.iter().fold(NodeAttributes::new(), |mut new_attributes, (k, v)| {
            if !self.contains_key(k) {
                new_attributes.insert(k.clone(), v.clone());
            }
            new_attributes
        });

        Ok((a, b))
    }

    fn invert(&self, other: &Self) -> Self {
        let base_inverted = other.iter().fold(NodeAttributes::new(), |mut attributes, (k, v)| {
            if other.get(k) != self.get(k) && self.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

        self.iter().fold(base_inverted, |mut attributes, (k, _)| {
            if other.get(k) != self.get(k) && !other.contains_key(k) {
                attributes.delete(k);
            }
            attributes
        })
    }
}

pub type AttributeKey = String;

#[derive(Eq, PartialEq, Hash, Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ValueType {
    IntType = 0,
    FloatType = 1,
    StrType = 2,
    BoolType = 3,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AttributeValue {
    pub ty: ValueType,
    pub value: Option<String>,
}

impl AttributeValue {
    pub fn empty() -> Self {
        Self {
            ty: ValueType::StrType,
            value: None,
        }
    }
    pub fn from_int(val: usize) -> Self {
        Self {
            ty: ValueType::IntType,
            value: Some(val.to_string()),
        }
    }

    pub fn from_float(val: f64) -> Self {
        Self {
            ty: ValueType::FloatType,
            value: Some(val.to_string()),
        }
    }

    pub fn from_bool(val: bool) -> Self {
        Self {
            ty: ValueType::BoolType,
            value: Some(val.to_string()),
        }
    }
    pub fn from_str(s: &str) -> Self {
        let value = if s.is_empty() { None } else { Some(s.to_string()) };
        Self {
            ty: ValueType::StrType,
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

pub struct NodeAttributeBuilder {
    attributes: NodeAttributes,
}

impl NodeAttributeBuilder {
    pub fn new() -> Self {
        Self {
            attributes: NodeAttributes::default(),
        }
    }

    pub fn insert<K: ToString, V: Into<AttributeValue>>(mut self, key: K, value: V) -> Self {
        self.attributes.insert(key, value);
        self
    }

    pub fn delete<K: ToString>(mut self, key: K) -> Self {
        self.attributes.delete(key);
        self
    }

    pub fn build(self) -> NodeAttributes {
        self.attributes
    }
}
