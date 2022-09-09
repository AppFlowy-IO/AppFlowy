use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub type AttributeMap = HashMap<String, Option<String>>;

#[derive(Clone, Serialize, Deserialize, Eq, PartialEq, Debug)]
pub struct NodeAttributes(pub AttributeMap);

impl Default for NodeAttributes {
    fn default() -> Self {
        Self::new()
    }
}

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

    pub fn to_inner(&self) -> AttributeMap {
        self.0.clone()
    }

    pub fn compose(a: &NodeAttributes, b: &NodeAttributes) -> NodeAttributes {
        let mut new_map: AttributeMap = b.0.clone();

        for (key, value) in &a.0 {
            if b.0.contains_key(key.as_str()) {
                new_map.insert(key.into(), value.clone());
            }
        }

        NodeAttributes(new_map)
    }
}
