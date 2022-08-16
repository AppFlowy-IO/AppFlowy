use std::collections::HashMap;

pub struct NodeAttributes(HashMap<String, Option<String>>);

impl NodeAttributes {
    pub fn new() -> NodeAttributes {
        NodeAttributes(HashMap::new())
    }
}
