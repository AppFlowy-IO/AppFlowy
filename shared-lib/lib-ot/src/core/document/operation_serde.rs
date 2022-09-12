use crate::core::{NodeBodyChangeset, Path};
use crate::text_delta::TextDelta;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserializer, Serializer};
use std::convert::TryInto;
use std::fmt;
use std::marker::PhantomData;

#[allow(dead_code)]
pub fn serialize_edit_body<S>(path: &Path, changeset: &NodeBodyChangeset, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut map = serializer.serialize_map(Some(3))?;
    map.serialize_key("path")?;
    map.serialize_value(path)?;

    match changeset {
        NodeBodyChangeset::Delta { delta, inverted } => {
            map.serialize_key("delta")?;
            map.serialize_value(delta)?;
            map.serialize_key("inverted")?;
            map.serialize_value(inverted)?;
            map.end()
        }
    }
}

#[allow(dead_code)]
pub fn deserialize_edit_body<'de, D>(deserializer: D) -> Result<(Path, NodeBodyChangeset), D::Error>
where
    D: Deserializer<'de>,
{
    struct NodeBodyChangesetVisitor();

    impl<'de> Visitor<'de> for NodeBodyChangesetVisitor {
        type Value = (Path, NodeBodyChangeset);

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("Expect Path and NodeBodyChangeset")
        }

        #[inline]
        fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
        where
            V: MapAccess<'de>,
        {
            let mut path: Option<Path> = None;
            let mut delta_changeset = DeltaBodyChangeset::<V::Error>::new();
            while let Some(key) = map.next_key()? {
                match key {
                    "delta" => {
                        if delta_changeset.delta.is_some() {
                            return Err(de::Error::duplicate_field("delta"));
                        }
                        delta_changeset.delta = Some(map.next_value()?);
                    }
                    "inverted" => {
                        if delta_changeset.inverted.is_some() {
                            return Err(de::Error::duplicate_field("inverted"));
                        }
                        delta_changeset.inverted = Some(map.next_value()?);
                    }
                    "path" => {
                        if path.is_some() {
                            return Err(de::Error::duplicate_field("path"));
                        }

                        path = Some(map.next_value::<Path>()?)
                    }
                    other => {
                        panic!("Unexpected key: {}", other);
                    }
                }
            }
            if path.is_none() {
                return Err(de::Error::missing_field("path"));
            }

            let changeset = delta_changeset.try_into()?;

            Ok((path.unwrap(), changeset))
        }
    }
    deserializer.deserialize_any(NodeBodyChangesetVisitor())
}

#[allow(dead_code)]
struct DeltaBodyChangeset<E> {
    delta: Option<TextDelta>,
    inverted: Option<TextDelta>,
    error: PhantomData<E>,
}

impl<E> DeltaBodyChangeset<E> {
    fn new() -> Self {
        Self {
            delta: None,
            inverted: None,
            error: PhantomData,
        }
    }
}

impl<E> std::convert::TryInto<NodeBodyChangeset> for DeltaBodyChangeset<E>
where
    E: de::Error,
{
    type Error = E;

    fn try_into(self) -> Result<NodeBodyChangeset, Self::Error> {
        if self.delta.is_none() {
            return Err(de::Error::missing_field("delta"));
        }

        if self.inverted.is_none() {
            return Err(de::Error::missing_field("inverted"));
        }
        let changeset = NodeBodyChangeset::Delta {
            delta: self.delta.unwrap(),
            inverted: self.inverted.unwrap(),
        };

        Ok(changeset)
    }
}
