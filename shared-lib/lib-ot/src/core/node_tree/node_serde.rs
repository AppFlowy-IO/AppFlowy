use super::Body;
use crate::text_delta::TextOperations;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserializer, Serializer};
use std::fmt;

pub fn serialize_body<S>(body: &Body, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut map = serializer.serialize_map(Some(3))?;
    match body {
        Body::Empty => {}
        Body::Delta(delta) => {
            map.serialize_key("delta")?;
            map.serialize_value(delta)?;
        }
    }
    map.end()
}

pub fn deserialize_body<'de, D>(deserializer: D) -> Result<Body, D::Error>
where
    D: Deserializer<'de>,
{
    struct NodeBodyVisitor();

    impl<'de> Visitor<'de> for NodeBodyVisitor {
        type Value = Body;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("Expect NodeBody")
        }

        fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
        where
            V: MapAccess<'de>,
        {
            let mut delta: Option<TextOperations> = None;
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

            if let Some(delta) = delta {
                return Ok(Body::Delta(delta));
            }

            Err(de::Error::missing_field("delta"))
        }
    }
    deserializer.deserialize_any(NodeBodyVisitor())
}
