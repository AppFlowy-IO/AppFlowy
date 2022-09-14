use crate::core::attributes::AttributeValue;

use serde::{
    de::{self, MapAccess, Visitor},
    Deserialize, Deserializer, Serialize, Serializer,
};
use std::fmt;

impl Serialize for AttributeValue {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match &self.ty {
            None => serializer.serialize_none(),
            Some(ty) => match ty {
                super::ValueType::IntType => {
                    if let Some(value) = self.int_value() {
                        serializer.serialize_i64(value)
                    } else {
                        serializer.serialize_none()
                    }
                }
                super::ValueType::FloatType => {
                    if let Some(value) = self.float_value() {
                        serializer.serialize_f64(value)
                    } else {
                        serializer.serialize_none()
                    }
                }
                super::ValueType::StrType => {
                    if let Some(value) = self.str_value() {
                        serializer.serialize_str(&value)
                    } else {
                        serializer.serialize_none()
                    }
                }
                super::ValueType::BoolType => {
                    if let Some(value) = self.bool_value() {
                        serializer.serialize_bool(value)
                    } else {
                        serializer.serialize_none()
                    }
                }
            },
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
                formatter.write_str("bool, usize or string")
            }

            fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_bool(value))
            }

            fn visit_i8<E>(self, value: i8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_i16<E>(self, value: i16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_u8<E>(self, value: u8) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_u16<E>(self, value: u16) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_u32<E>(self, value: u32) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_int(value as usize))
            }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::from_string(s))
            }

            fn visit_none<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(AttributeValue::none())
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                // the value that contains null will be processed here.
                Ok(AttributeValue::none())
            }

            fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                // https://github.com/serde-rs/json/issues/505
                let mut map = map;
                let value = map.next_value::<AttributeValue>()?;
                Ok(value)
            }
        }

        deserializer.deserialize_any(AttributeValueVisitor)
    }
}
