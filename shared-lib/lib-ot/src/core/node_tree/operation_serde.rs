use crate::core::{DeltaOperations, NodeOperation, NodeOperations};
use serde::de::{MapAccess, SeqAccess, Visitor};
use serde::ser::{SerializeMap, SerializeSeq};
use serde::{de, Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;

impl Serialize for NodeOperations {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let operations = self.operations.values();
        let mut seq = serializer.serialize_seq(Some(operations.len()))?;
        for operation in operations {
            let _ = seq.serialize_element(&operation)?;
        }
        seq.end()
    }
}

impl<'de> Deserialize<'de> for NodeOperations {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct NodeOperationsVisitor();

        impl<'de> Visitor<'de> for NodeOperationsVisitor {
            type Value = NodeOperations;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Expected node operation")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut operations = NodeOperations::new();
                while let Some(operation) = seq.next_element::<NodeOperation>()? {
                    operations.push_op(operation);
                }
                Ok(operations)
            }
        }

        deserializer.deserialize_any(NodeOperationsVisitor())
    }
}
