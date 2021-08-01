use crate::{attributes::Attributes, delta::Delta, operation::Operation};
use serde::{
    de,
    de::{MapAccess, SeqAccess, Visitor},
    ser::{SerializeMap, SerializeSeq},
    Deserialize,
    Deserializer,
    Serialize,
    Serializer,
};
use std::{collections::HashMap, fmt};

impl Serialize for Operation {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            Operation::Retain(retain) => retain.serialize(serializer),
            Operation::Delete(i) => {
                let mut map = serializer.serialize_map(Some(1))?;
                map.serialize_entry("delete", i)?;
                map.end()
            },
            Operation::Insert(insert) => insert.serialize(serializer),
        }
    }
}

impl<'de> Deserialize<'de> for Operation {
    fn deserialize<D>(deserializer: D) -> Result<Operation, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OperationVisitor;

        impl<'de> Visitor<'de> for OperationVisitor {
            type Value = Operation;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("an integer between -2^64 and 2^63 or a string")
            }

            fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
            where
                V: MapAccess<'de>,
            {
                let mut operation = None;
                let mut attributes = None;
                while let Some(key) = map.next_key()? {
                    match key {
                        "delete" => {
                            if operation.is_some() {
                                return Err(de::Error::duplicate_field("operation"));
                            }
                            operation = Some(Operation::Delete(map.next_value()?));
                        },
                        "retain" => {
                            if operation.is_some() {
                                return Err(de::Error::duplicate_field("operation"));
                            }
                            let i: u64 = map.next_value()?;
                            operation = Some(Operation::Retain(i.into()));
                        },
                        "insert" => {
                            if operation.is_some() {
                                return Err(de::Error::duplicate_field("operation"));
                            }
                            let i: String = map.next_value()?;
                            operation = Some(Operation::Insert(i.into()));
                        },
                        "attributes" => {
                            if attributes.is_some() {
                                return Err(de::Error::duplicate_field("attributes"));
                            }
                            let map: Attributes = map.next_value()?;
                            attributes = Some(map);
                        },
                        _ => panic!(),
                    }
                }
                match operation {
                    None => Err(de::Error::missing_field("operation")),
                    Some(mut operation) => {
                        operation.set_attributes(attributes);
                        Ok(operation)
                    },
                }
            }
        }

        deserializer.deserialize_any(OperationVisitor)
    }
}

impl Serialize for Delta {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut seq = serializer.serialize_seq(Some(self.ops.len()))?;
        for op in self.ops.iter() {
            seq.serialize_element(op)?;
        }
        seq.end()
    }
}

impl<'de> Deserialize<'de> for Delta {
    fn deserialize<D>(deserializer: D) -> Result<Delta, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OperationSeqVisitor;

        impl<'de> Visitor<'de> for OperationSeqVisitor {
            type Value = Delta;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a sequence")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut o = Delta::default();
                while let Some(op) = seq.next_element()? {
                    o.add(op);
                }
                Ok(o)
            }
        }

        deserializer.deserialize_seq(OperationSeqVisitor)
    }
}
