use serde::de::Visitor;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use std::fmt;
#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct TrashRevision {
    pub id: String,

    pub name: String,

    pub modified_time: i64,

    pub create_time: i64,

    pub ty: TrashTypeRevision,
}

#[derive(Eq, PartialEq, Debug, Clone, Serialize_repr)]
#[repr(u8)]
pub enum TrashTypeRevision {
    Unknown = 0,
    TrashView = 1,
    TrashApp = 2,
}
impl<'de> serde::Deserialize<'de> for TrashTypeRevision {
    fn deserialize<D>(deserializer: D) -> core::result::Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        struct TrashTypeVisitor();

        impl<'de> Visitor<'de> for TrashTypeVisitor {
            type Value = TrashTypeRevision;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("expected enum TrashTypeRevision with type: u8")
            }

            fn visit_i8<E>(self, v: i8) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_i16<E>(self, v: i16) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_i32<E>(self, v: i32) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_i64<E>(self, v: i64) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_u8<E>(self, v: u8) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                let ty = match v {
                    0 => TrashTypeRevision::Unknown,
                    1 => TrashTypeRevision::TrashView,
                    2 => TrashTypeRevision::TrashApp,
                    _ => TrashTypeRevision::Unknown,
                };

                Ok(ty)
            }

            fn visit_u16<E>(self, v: u16) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_u32<E>(self, v: u32) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_u64<E>(self, v: u64) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                self.visit_u8(v as u8)
            }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: serde::de::Error,
            {
                let value = match s {
                    "Unknown" => TrashTypeRevision::Unknown,
                    "TrashView" => TrashTypeRevision::TrashView,
                    "TrashApp" => TrashTypeRevision::TrashApp,
                    _ => TrashTypeRevision::Unknown,
                };
                Ok(value)
            }
        }

        deserializer.deserialize_any(TrashTypeVisitor())
    }
}
impl std::default::Default for TrashTypeRevision {
    fn default() -> Self {
        TrashTypeRevision::Unknown
    }
}

impl std::convert::From<TrashTypeRevision> for u8 {
    fn from(rev: TrashTypeRevision) -> Self {
        match rev {
            TrashTypeRevision::Unknown => 0,
            TrashTypeRevision::TrashView => 1,
            TrashTypeRevision::TrashApp => 2,
        }
    }
}
