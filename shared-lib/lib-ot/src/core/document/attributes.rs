use std::collections::HashMap;

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct NodeAttributes(pub HashMap<String, Option<String>>);

impl Default for NodeAttributes {
    fn default() -> Self {
        Self::new()
    }
}

impl NodeAttributes {
    pub fn new() -> NodeAttributes {
        NodeAttributes(HashMap::new())
    }

    pub fn compose(a: &NodeAttributes, b: &NodeAttributes) -> NodeAttributes {
        let mut new_map: HashMap<String, Option<String>> = b.0.clone();

        for (key, value) in &a.0 {
            if b.0.contains_key(key.as_str()) {
                new_map.insert(key.into(), value.clone());
            }
        }

        NodeAttributes(new_map)
    }
}
