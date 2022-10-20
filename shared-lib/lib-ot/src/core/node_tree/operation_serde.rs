use crate::core::{AttributeHashMap, Changeset, Path};
use crate::text_delta::TextOperations;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserializer, Serializer};
use std::convert::TryInto;
use std::fmt;
use std::marker::PhantomData;

#[allow(dead_code)]
pub fn serialize_changeset<S>(path: &Path, changeset: &Changeset, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut map = serializer.serialize_map(Some(3))?;
    map.serialize_key("path")?;
    map.serialize_value(path)?;

    match changeset {
        Changeset::Delta { delta, inverted } => {
            map.serialize_key("delta")?;
            map.serialize_value(delta)?;
            map.serialize_key("inverted")?;
            map.serialize_value(inverted)?;
            map.end()
        }
        Changeset::Attributes { new, old } => {
            map.serialize_key("new")?;
            map.serialize_value(new)?;
            map.serialize_key("old")?;
            map.serialize_value(old)?;
            map.end()
        }
    }
}

#[allow(dead_code)]
pub fn deserialize_changeset<'de, D>(deserializer: D) -> Result<(Path, Changeset), D::Error>
where
    D: Deserializer<'de>,
{
    struct ChangesetVisitor();

    impl<'de> Visitor<'de> for ChangesetVisitor {
        type Value = (Path, Changeset);

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("Expect Path and Changeset")
        }

        #[inline]
        fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
        where
            V: MapAccess<'de>,
        {
            let mut path: Option<Path> = None;
            let mut delta_changeset = DeltaChangeset::<V::Error>::new();
            let mut attribute_changeset = AttributeChangeset::new();
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
                    "new" => {
                        if attribute_changeset.new.is_some() {
                            return Err(de::Error::duplicate_field("new"));
                        }
                        attribute_changeset.new = Some(map.next_value()?);
                    }
                    "old" => {
                        if attribute_changeset.old.is_some() {
                            return Err(de::Error::duplicate_field("old"));
                        }
                        attribute_changeset.old = Some(map.next_value()?);
                    }
                    other => {
                        tracing::warn!("Unexpected key: {}", other);
                        panic!()
                    }
                }
            }
            if path.is_none() {
                return Err(de::Error::missing_field("path"));
            }

            let mut changeset: Changeset;
            if !delta_changeset.is_empty() {
                changeset = delta_changeset.try_into()?
            } else {
                changeset = attribute_changeset.try_into()?;
            }

            Ok((path.unwrap(), changeset))
        }
    }
    deserializer.deserialize_any(ChangesetVisitor())
}

struct DeltaChangeset<E> {
    delta: Option<TextOperations>,
    inverted: Option<TextOperations>,
    error: PhantomData<E>,
}

impl<E> DeltaChangeset<E> {
    fn new() -> Self {
        Self {
            delta: None,
            inverted: None,
            error: PhantomData,
        }
    }

    fn is_empty(&self) -> bool {
        self.delta.is_none() && self.inverted.is_none()
    }
}

impl<E> std::convert::TryInto<Changeset> for DeltaChangeset<E>
where
    E: de::Error,
{
    type Error = E;

    fn try_into(self) -> Result<Changeset, Self::Error> {
        if self.delta.is_none() {
            return Err(de::Error::missing_field("delta"));
        }

        if self.inverted.is_none() {
            return Err(de::Error::missing_field("inverted"));
        }
        let changeset = Changeset::Delta {
            delta: self.delta.unwrap(),
            inverted: self.inverted.unwrap(),
        };

        Ok(changeset)
    }
}
struct AttributeChangeset<E> {
    new: Option<AttributeHashMap>,
    old: Option<AttributeHashMap>,
    error: PhantomData<E>,
}

impl<E> AttributeChangeset<E> {
    fn new() -> Self {
        Self {
            new: Default::default(),
            old: Default::default(),
            error: PhantomData,
        }
    }

    fn is_empty(&self) -> bool {
        self.new.is_none() && self.old.is_none()
    }
}

impl<E> std::convert::TryInto<Changeset> for AttributeChangeset<E>
where
    E: de::Error,
{
    type Error = E;

    fn try_into(self) -> Result<Changeset, Self::Error> {
        if self.new.is_none() {
            return Err(de::Error::missing_field("new"));
        }

        if self.old.is_none() {
            return Err(de::Error::missing_field("old"));
        }

        Ok(Changeset::Attributes {
            new: self.new.unwrap(),
            old: self.old.unwrap(),
        })
    }
}
