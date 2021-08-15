use crate::core::AttributeValue;
use serde::{de, de::Visitor, Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;

impl Serialize for AttributeValue {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for AttributeValue {
    fn deserialize<D>(deserializer: D) -> Result<AttributeValue, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OperationSeqVisitor;

        impl<'de> Visitor<'de> for OperationSeqVisitor {
            type Value = AttributeValue;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a string")
            }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                let attribute_value = AttributeValue(s.to_owned());
                Ok(attribute_value)
            }
        }

        deserializer.deserialize_str(OperationSeqVisitor)
    }
}
