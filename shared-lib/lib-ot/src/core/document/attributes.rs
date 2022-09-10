use crate::core::OperationTransform;
use crate::errors::OTError;
use serde::{Deserialize, Serialize};
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

    pub fn delete(&mut self, key: &AttributeKey) {
        self.insert(key.clone(), AttributeValue(None));
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

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct AttributeValue(pub Option<String>);

impl std::convert::From<&usize> for AttributeValue {
    fn from(val: &usize) -> Self {
        AttributeValue::from(*val)
    }
}

impl std::convert::From<usize> for AttributeValue {
    fn from(val: usize) -> Self {
        if val > 0_usize {
            AttributeValue(Some(format!("{}", val)))
        } else {
            AttributeValue(None)
        }
    }
}

impl std::convert::From<&str> for AttributeValue {
    fn from(val: &str) -> Self {
        val.to_owned().into()
    }
}

impl std::convert::From<String> for AttributeValue {
    fn from(val: String) -> Self {
        if val.is_empty() {
            AttributeValue(None)
        } else {
            AttributeValue(Some(val))
        }
    }
}

impl std::convert::From<&bool> for AttributeValue {
    fn from(val: &bool) -> Self {
        AttributeValue::from(*val)
    }
}

impl std::convert::From<bool> for AttributeValue {
    fn from(val: bool) -> Self {
        let val = match val {
            true => Some("true".to_owned()),
            false => None,
        };
        AttributeValue(val)
    }
}
