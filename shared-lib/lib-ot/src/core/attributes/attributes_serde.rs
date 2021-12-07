#[rustfmt::skip]
use crate::core::RichTextAttributeValue;
use crate::core::{RichTextAttribute, RichTextAttributeKey, RichTextAttributes};
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

impl Serialize for RichTextAttribute {
    fn serialize<S>(&self, serializer: S) -> Result<<S as Serializer>::Ok, <S as Serializer>::Error>
    where
        S: Serializer,
    {
        let mut map = serializer.serialize_map(Some(1))?;
        let _ = serial_attribute(&mut map, &self.key, &self.value)?;
        map.end()
    }
}

impl Serialize for RichTextAttributes {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        if self.is_empty() {
            return serializer.serialize_none();
        }

        let mut map = serializer.serialize_map(Some(self.inner.len()))?;
        for (k, v) in &self.inner {
            let _ = serial_attribute(&mut map, k, v)?;
        }
        map.end()
    }
}

fn serial_attribute<S, E>(
    map_serializer: &mut S,
    key: &RichTextAttributeKey,
    value: &RichTextAttributeValue,
) -> Result<(), E>
where
    S: SerializeMap,
    E: From<<S as SerializeMap>::Error>,
{
    if let Some(v) = &value.0 {
        match key {
            RichTextAttributeKey::Bold
            | RichTextAttributeKey::Italic
            | RichTextAttributeKey::Underline
            | RichTextAttributeKey::StrikeThrough
            | RichTextAttributeKey::CodeBlock
            | RichTextAttributeKey::InlineCode
            | RichTextAttributeKey::BlockQuote => match &v.parse::<bool>() {
                Ok(value) => map_serializer.serialize_entry(&key, value)?,
                Err(e) => log::error!("Serial {:?} failed. {:?}", &key, e),
            },

            RichTextAttributeKey::Font
            | RichTextAttributeKey::Size
            | RichTextAttributeKey::Header
            | RichTextAttributeKey::Indent
            | RichTextAttributeKey::Width
            | RichTextAttributeKey::Height => match &v.parse::<i32>() {
                Ok(value) => map_serializer.serialize_entry(&key, value)?,
                Err(e) => log::error!("Serial {:?} failed. {:?}", &key, e),
            },

            RichTextAttributeKey::Link
            | RichTextAttributeKey::Color
            | RichTextAttributeKey::Background
            | RichTextAttributeKey::Align
            | RichTextAttributeKey::List => {
                map_serializer.serialize_entry(&key, v)?;
            },
        }
    } else {
        map_serializer.serialize_entry(&key, "")?;
    }
    Ok(())
}

impl<'de> Deserialize<'de> for RichTextAttributes {
    fn deserialize<D>(deserializer: D) -> Result<RichTextAttributes, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributesVisitor;
        impl<'de> Visitor<'de> for AttributesVisitor {
            type Value = RichTextAttributes;
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result { formatter.write_str("Expect map") }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut attributes = RichTextAttributes::new();
                while let Some(key) = map.next_key::<RichTextAttributeKey>()? {
                    let value = map.next_value::<RichTextAttributeValue>()?;
                    attributes.add_kv(key, value);
                }

                Ok(attributes)
            }
        }
        deserializer.deserialize_map(AttributesVisitor {})
    }
}

impl Serialize for RichTextAttributeValue {
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

impl<'de> Deserialize<'de> for RichTextAttributeValue {
    fn deserialize<D>(deserializer: D) -> Result<RichTextAttributeValue, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributeValueVisitor;
        impl<'de> Visitor<'de> for AttributeValueVisitor {
            type Value = RichTextAttributeValue;
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
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
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i16<E>(self, value: i16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u8<E>(self, value: u8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u16<E>(self, value: u16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u32<E>(self, value: u32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(RichTextAttributeValue(Some(format!("{}", value))))
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
                Ok(RichTextAttributeValue(None))
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                // the value that contains null will be processed here.
                Ok(RichTextAttributeValue(None))
            }

            fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                // https://github.com/serde-rs/json/issues/505
                let mut map = map;
                let value = map.next_value::<RichTextAttributeValue>()?;
                Ok(value)
            }
        }

        deserializer.deserialize_any(AttributeValueVisitor)
    }
}
