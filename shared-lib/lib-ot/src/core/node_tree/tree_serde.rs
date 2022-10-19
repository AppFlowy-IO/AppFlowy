use crate::core::{NodeData, NodeTree, NodeTreeContext};
use serde::de::{MapAccess, Visitor};
use serde::ser::SerializeSeq;
use serde::{de, Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;
use std::fmt::Debug;
use std::marker::PhantomData;

impl Serialize for NodeTree {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let root_node_id = self.root_node_id();
        let mut children = self.get_children_ids(root_node_id);
        if children.is_empty() {
            return serializer.serialize_str("");
        }
        if children.len() == 1 {
            let node_id = children.pop().unwrap();
            match self.get_node_data(node_id) {
                None => serializer.serialize_str(""),
                Some(node_data) => node_data.serialize(serializer),
            }
        } else {
            let mut seq = serializer.serialize_seq(Some(children.len()))?;
            for child in children {
                if let Some(child_node_data) = self.get_node_data(child) {
                    let _ = seq.serialize_element(&child_node_data)?;
                }
            }
            seq.end()
        }
    }
}

impl<'de> Deserialize<'de> for NodeTree {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct NodeTreeVisitor(PhantomData<NodeData>);

        impl<'de> Visitor<'de> for NodeTreeVisitor {
            type Value = NodeData;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Expected node data tree")
            }

            fn visit_map<V>(self, map: V) -> Result<Self::Value, V::Error>
            where
                V: MapAccess<'de>,
            {
                // Forward the deserialization to NodeData
                Deserialize::deserialize(de::value::MapAccessDeserializer::new(map))
            }
        }

        let node_data: NodeData = deserializer.deserialize_any(NodeTreeVisitor(PhantomData))?;
        Ok(NodeTree::from_node_data(node_data, NodeTreeContext::default()).unwrap())
    }
}
