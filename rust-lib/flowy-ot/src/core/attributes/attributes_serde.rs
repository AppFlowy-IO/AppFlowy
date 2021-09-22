#[rustfmt::skip]
use crate::core::AttributeValue;
use crate::core::{AttributeKey, Attributes};
use serde::{
    de,
    de::{MapAccess, Visitor},
    ser::SerializeMap,
    Deserialize,
    Deserializer,
    Serialize,
    Serializer,
};
use std::fmt;

impl Serialize for Attributes {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        if self.is_empty() {
            return serializer.serialize_none();
        }

        let mut map = serializer.serialize_map(Some(self.inner.len()))?;
        for (k, v) in &self.inner {
            if let Some(v) = &v.0 {
                match k {
                    AttributeKey::Bold
                    | AttributeKey::Italic
                    | AttributeKey::Underline
                    | AttributeKey::StrikeThrough
                    | AttributeKey::CodeBlock
                    | AttributeKey::QuoteBlock => match &v.parse::<bool>() {
                        Ok(value) => map.serialize_entry(k, value)?,
                        Err(e) => log::error!("Serial {:?} failed. {:?}", k, e),
                    },

                    AttributeKey::Font
                    | AttributeKey::Size
                    | AttributeKey::Header
                    | AttributeKey::Indent
                    | AttributeKey::Width
                    | AttributeKey::Height => match &v.parse::<i32>() {
                        Ok(value) => map.serialize_entry(k, value)?,
                        Err(e) => log::error!("Serial {:?} failed. {:?}", k, e),
                    },

                    AttributeKey::Link | AttributeKey::Color | AttributeKey::Background | AttributeKey::Align | AttributeKey::List => {
                        map.serialize_entry(k, v)?;
                    },
                }
            }
        }
        map.end()
    }
}

impl<'de> Deserialize<'de> for Attributes {
    fn deserialize<D>(deserializer: D) -> Result<Attributes, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributesVisitor;
        impl<'de> Visitor<'de> for AttributesVisitor {
            type Value = Attributes;
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result { formatter.write_str("Expect map") }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut attributes = Attributes::new();
                while let Some(key) = map.next_key::<AttributeKey>()? {
                    log::warn!("{:?}", key);
                    let value = map.next_value::<AttributeValue>()?;
                    attributes.add_kv(key, value);
                }

                Ok(attributes)
            }
        }
        deserializer.deserialize_map(AttributesVisitor {})
    }
}

impl Serialize for AttributeValue {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match &self.0 {
            None => serializer.serialize_none(),
            Some(val) => serializer.serialize_str(val),
        }
    }
}

impl<'de> Deserialize<'de> for AttributeValue {
    fn deserialize<D>(deserializer: D) -> Result<AttributeValue, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributeValueVisitor;
        impl<'de> Visitor<'de> for AttributeValueVisitor {
            type Value = AttributeValue;
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                //
                formatter.write_str("bool, usize or string")
            }
            fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(value.into())
            }

            fn visit_i8<E>(self, value: i8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_i16<E>(self, value: i16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_u8<E>(self, value: u8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_u16<E>(self, value: u16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_u32<E>(self, value: u32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(Some(format!("{}", value))))
            }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(s.into())
            }

            fn visit_none<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(None))
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue(None))
            }
        }

        deserializer.deserialize_any(AttributeValueVisitor)
    }
}
