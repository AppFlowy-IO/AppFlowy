use std::collections::HashMap;

#[derive(Clone)]
pub struct NodeAttributes(HashMap<String, Option<String>>);

impl NodeAttributes {
    pub fn new() -> NodeAttributes {
        NodeAttributes(HashMap::new())
    }
}
