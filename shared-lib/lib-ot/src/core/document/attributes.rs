use std::collections::HashMap;

#[derive(Clone)]
pub struct NodeAttributes(HashMap<String, Option<String>>);

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
