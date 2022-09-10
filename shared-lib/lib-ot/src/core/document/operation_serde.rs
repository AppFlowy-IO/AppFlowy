use crate::core::{NodeBodyChangeset, Path};
use serde::ser::SerializeMap;
use serde::Serializer;

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

// pub fn deserialize_edit_body<'de, D>(deserializer: D) -> Result<NodeBodyChangeset, D::Error>
// where
//     D: Deserializer<'de>,
// {
//     todo!()
// }
