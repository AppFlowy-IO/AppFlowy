#[rustfmt::skip]
use crate::rich_text::{TextAttribute, TextAttributeKey, TextAttributes, TextAttributeValue};
use serde::{
    de,
    de::{MapAccess, Visitor},
    ser::SerializeMap,
    Deserialize, Deserializer, Serialize, Serializer,
};
use std::fmt;

impl Serialize for TextAttribute {
    fn serialize<S>(&self, serializer: S) -> Result<<S as Serializer>::Ok, <S as Serializer>::Error>
    where
        S: Serializer,
    {
        let mut map = serializer.serialize_map(Some(1))?;
        let _ = serial_attribute(&mut map, &self.key, &self.value)?;
        map.end()
    }
}

impl Serialize for TextAttributes {
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

fn serial_attribute<S, E>(map_serializer: &mut S, key: &TextAttributeKey, value: &TextAttributeValue) -> Result<(), E>
where
    S: SerializeMap,
    E: From<<S as SerializeMap>::Error>,
{
    if let Some(v) = &value.0 {
        match key {
            TextAttributeKey::Bold
            | TextAttributeKey::Italic
            | TextAttributeKey::Underline
            | TextAttributeKey::StrikeThrough
            | TextAttributeKey::CodeBlock
            | TextAttributeKey::InlineCode
            | TextAttributeKey::BlockQuote => match &v.parse::<bool>() {
                Ok(value) => map_serializer.serialize_entry(&key, value)?,
                Err(e) => log::error!("Serial {:?} failed. {:?}", &key, e),
            },

            TextAttributeKey::Font
            | TextAttributeKey::Size
            | TextAttributeKey::Header
            | TextAttributeKey::Indent
            | TextAttributeKey::Width
            | TextAttributeKey::Height => match &v.parse::<i32>() {
                Ok(value) => map_serializer.serialize_entry(&key, value)?,
                Err(e) => log::error!("Serial {:?} failed. {:?}", &key, e),
            },

            TextAttributeKey::Link
            | TextAttributeKey::Color
            | TextAttributeKey::Background
            | TextAttributeKey::Align
            | TextAttributeKey::List => {
                map_serializer.serialize_entry(&key, v)?;
            }
        }
    } else {
        map_serializer.serialize_entry(&key, "")?;
    }
    Ok(())
}

impl<'de> Deserialize<'de> for TextAttributes {
    fn deserialize<D>(deserializer: D) -> Result<TextAttributes, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributesVisitor;
        impl<'de> Visitor<'de> for AttributesVisitor {
            type Value = TextAttributes;
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Expect map")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut attributes = TextAttributes::new();
                while let Some(key) = map.next_key::<TextAttributeKey>()? {
                    let value = map.next_value::<TextAttributeValue>()?;
                    attributes.insert(key, value);
                }

                Ok(attributes)
            }
        }
        deserializer.deserialize_map(AttributesVisitor {})
    }
}

impl Serialize for TextAttributeValue {
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

impl<'de> Deserialize<'de> for TextAttributeValue {
    fn deserialize<D>(deserializer: D) -> Result<TextAttributeValue, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct AttributeValueVisitor;
        impl<'de> Visitor<'de> for AttributeValueVisitor {
            type Value = TextAttributeValue;
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
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i16<E>(self, value: i16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u8<E>(self, value: u8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u16<E>(self, value: u16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u32<E>(self, value: u32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(TextAttributeValue(Some(format!("{}", value))))
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
                Ok(TextAttributeValue(None))
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                // the value that contains null will be processed here.
                Ok(TextAttributeValue(None))
            }

            fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                // https://github.com/serde-rs/json/issues/505
                let mut map = map;
                let value = map.next_value::<TextAttributeValue>()?;
                Ok(value)
            }
        }

        deserializer.deserialize_any(AttributeValueVisitor)
    }
}
