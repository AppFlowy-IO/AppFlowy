use super::NodeBody;
use crate::rich_text::RichTextDelta;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserializer, Serializer};
use std::fmt;

pub fn serialize_body<S>(body: &NodeBody, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut map = serializer.serialize_map(Some(3))?;
    match body {
        NodeBody::Empty => {}
        NodeBody::Delta(delta) => {
            map.serialize_key("delta")?;
            map.serialize_value(delta)?;
        }
    }
    map.end()
}

pub fn deserialize_body<'de, D>(deserializer: D) -> Result<NodeBody, D::Error>
where
    D: Deserializer<'de>,
{
    struct NodeBodyVisitor();

    impl<'de> Visitor<'de> for NodeBodyVisitor {
        type Value = NodeBody;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("Expect NodeBody")
        }

        fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
        where
            A: de::SeqAccess<'de>,
        {
            let mut delta = RichTextDelta::default();
            while let Some(op) = seq.next_element()? {
                delta.add(op);
            }
            Ok(NodeBody::Delta(delta))
        }

        #[inline]
        fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
        where
            V: MapAccess<'de>,
        {
            let mut delta: Option<RichTextDelta> = None;
            while let Some(key) = map.next_key()? {
                match key {
                    "delta" => {
                        if delta.is_some() {
                            return Err(de::Error::duplicate_field("delta"));
                        }
                        delta = Some(map.next_value()?);
                    }
                    other => {
                        panic!("Unexpected key: {}", other);
                    }
                }
            }

            if delta.is_some() {
                return Ok(NodeBody::Delta(delta.unwrap()));
            }

            Err(de::Error::missing_field("delta"))
        }
    }
    deserializer.deserialize_any(NodeBodyVisitor())
}
