use crate::core::delta::operation::{DeltaOperation, Insert, OperationAttributes, Retain};
use crate::core::ot_str::OTString;
use serde::{
    de,
    de::{MapAccess, SeqAccess, Visitor},
    ser::SerializeMap,
    Deserialize, Deserializer, Serialize, Serializer,
};
use std::{fmt, marker::PhantomData};

impl<T> Serialize for DeltaOperation<T>
where
    T: OperationAttributes + Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            DeltaOperation::Retain(retain) => retain.serialize(serializer),
            DeltaOperation::Delete(i) => {
                let mut map = serializer.serialize_map(Some(1))?;
                map.serialize_entry("delete", i)?;
                map.end()
            }
            DeltaOperation::Insert(insert) => insert.serialize(serializer),
        }
    }
}

impl<'de, T> Deserialize<'de> for DeltaOperation<T>
where
    T: OperationAttributes + Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<DeltaOperation<T>, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OperationVisitor<T>(PhantomData<fn() -> T>);

        impl<'de, T> Visitor<'de> for OperationVisitor<T>
        where
            T: OperationAttributes + Deserialize<'de>,
        {
            type Value = DeltaOperation<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("an integer between -2^64 and 2^63 or a string")
            }

            #[inline]
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
                            operation = Some(DeltaOperation::<T>::Delete(map.next_value()?));
                        }
                        "retain" => {
                            if operation.is_some() {
                                return Err(de::Error::duplicate_field("operation"));
                            }
                            let i: usize = map.next_value()?;
                            operation = Some(DeltaOperation::<T>::Retain(i.into()));
                        }
                        "insert" => {
                            if operation.is_some() {
                                return Err(de::Error::duplicate_field("operation"));
                            }
                            let i: String = map.next_value()?;
                            operation = Some(DeltaOperation::<T>::Insert(i.into()));
                        }
                        "attributes" => {
                            if attributes.is_some() {
                                return Err(de::Error::duplicate_field("attributes"));
                            }
                            let map: T = map.next_value()?;
                            attributes = Some(map);
                        }
                        _ => panic!(),
                    }
                }
                match operation {
                    None => Err(de::Error::missing_field("operation")),
                    Some(mut operation) => {
                        if !operation.is_delete() {
                            operation.set_attributes(attributes.unwrap_or_default());
                        }
                        Ok(operation)
                    }
                }
            }
        }

        deserializer.deserialize_any(OperationVisitor(PhantomData))
    }
}

impl<T> Serialize for Retain<T>
where
    T: OperationAttributes + Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let len = false as usize + 1 + if self.attributes.is_empty() { 0 } else { 1 };
        let mut serde_state = serializer.serialize_struct("Retain", len)?;
        let _ = serde::ser::SerializeStruct::serialize_field(&mut serde_state, "retain", &self.n)?;
        if !self.attributes.is_empty() {
            let _ = serde::ser::SerializeStruct::serialize_field(&mut serde_state, "attributes", &self.attributes)?;
        }
        serde::ser::SerializeStruct::end(serde_state)
    }
}

impl<'de, T> Deserialize<'de> for Retain<T>
where
    T: OperationAttributes + Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, <D as Deserializer<'de>>::Error>
    where
        D: Deserializer<'de>,
    {
        struct RetainVisitor<T>(PhantomData<fn() -> T>);

        impl<'de, T> Visitor<'de> for RetainVisitor<T>
        where
            T: OperationAttributes + Deserialize<'de>,
        {
            type Value = Retain<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("struct Retain")
            }

            #[inline]
            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let len = match serde::de::SeqAccess::next_element::<usize>(&mut seq)? {
                    Some(val) => val,
                    None => {
                        return Err(de::Error::invalid_length(0, &"struct Retain with 2 elements"));
                    }
                };

                let attributes = match serde::de::SeqAccess::next_element::<T>(&mut seq)? {
                    Some(val) => val,
                    None => {
                        return Err(de::Error::invalid_length(1, &"struct Retain with 2 elements"));
                    }
                };

                Ok(Retain::<T> { n: len, attributes })
            }

            #[inline]
            fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
            where
                V: MapAccess<'de>,
            {
                let mut len: Option<usize> = None;
                let mut attributes: Option<T> = None;
                while let Some(key) = map.next_key()? {
                    match key {
                        "retain" => {
                            if len.is_some() {
                                return Err(de::Error::duplicate_field("retain"));
                            }
                            len = Some(map.next_value()?);
                        }
                        "attributes" => {
                            if attributes.is_some() {
                                return Err(de::Error::duplicate_field("attributes"));
                            }
                            attributes = Some(map.next_value()?);
                        }
                        _ => panic!(),
                    }
                }

                if len.is_none() {
                    return Err(de::Error::missing_field("len"));
                }

                if attributes.is_none() {
                    return Err(de::Error::missing_field("attributes"));
                }
                Ok(Retain::<T> {
                    n: len.unwrap(),
                    attributes: attributes.unwrap(),
                })
            }
        }
        const FIELDS: &[&str] = &["retain", "attributes"];
        serde::Deserializer::deserialize_struct(deserializer, "Retain", FIELDS, RetainVisitor(PhantomData))
    }
}

impl<T> Serialize for Insert<T>
where
    T: OperationAttributes + Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let len = false as usize + 1 + if self.attributes.is_empty() { 0 } else { 1 };
        let mut serde_state = serializer.serialize_struct("Insert", len)?;
        let _ = serde::ser::SerializeStruct::serialize_field(&mut serde_state, "insert", &self.s)?;
        if !self.attributes.is_empty() {
            let _ = serde::ser::SerializeStruct::serialize_field(&mut serde_state, "attributes", &self.attributes)?;
        }
        serde::ser::SerializeStruct::end(serde_state)
    }
}

impl<'de, T> Deserialize<'de> for Insert<T>
where
    T: OperationAttributes + Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, <D as Deserializer<'de>>::Error>
    where
        D: Deserializer<'de>,
    {
        struct InsertVisitor<T>(PhantomData<fn() -> T>);

        impl<'de, T> Visitor<'de> for InsertVisitor<T>
        where
            T: OperationAttributes + Deserialize<'de>,
        {
            type Value = Insert<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("struct Insert")
            }

            #[inline]
            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let s = match serde::de::SeqAccess::next_element::<OTString>(&mut seq)? {
                    Some(val) => val,
                    None => {
                        return Err(de::Error::invalid_length(0, &"struct Insert with 2 elements"));
                    }
                };

                let attributes = match serde::de::SeqAccess::next_element::<T>(&mut seq)? {
                    Some(val) => val,
                    None => {
                        return Err(de::Error::invalid_length(1, &"struct Retain with 2 elements"));
                    }
                };

                Ok(Insert::<T> { s, attributes })
            }

            #[inline]
            fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
            where
                V: MapAccess<'de>,
            {
                let mut s: Option<OTString> = None;
                let mut attributes: Option<T> = None;
                while let Some(key) = map.next_key()? {
                    match key {
                        "insert" => {
                            if s.is_some() {
                                return Err(de::Error::duplicate_field("insert"));
                            }
                            s = Some(map.next_value()?);
                        }
                        "attributes" => {
                            if attributes.is_some() {
                                return Err(de::Error::duplicate_field("attributes"));
                            }
                            attributes = Some(map.next_value()?);
                        }
                        _ => panic!(),
                    }
                }

                if s.is_none() {
                    return Err(de::Error::missing_field("s"));
                }

                if attributes.is_none() {
                    return Err(de::Error::missing_field("attributes"));
                }
                Ok(Insert::<T> {
                    s: s.unwrap(),
                    attributes: attributes.unwrap(),
                })
            }
        }
        const FIELDS: &[&str] = &["insert", "attributes"];
        serde::Deserializer::deserialize_struct(deserializer, "Insert", FIELDS, InsertVisitor(PhantomData))
    }
}
