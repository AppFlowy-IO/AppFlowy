use crate::core::Extension;
use serde::ser::SerializeMap;
use serde::Serializer;

#[allow(dead_code)]
pub fn serialize_extension<S>(extension: &Extension, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    match extension {
        Extension::Empty => {
            let map = serializer.serialize_map(None)?;
            map.end()
        }
        Extension::TextSelection {
            before_selection,
            after_selection,
        } => {
            let mut map = serializer.serialize_map(Some(2))?;
            map.serialize_key("before_selection")?;
            map.serialize_value(before_selection)?;

            map.serialize_key("after_selection")?;
            map.serialize_value(after_selection)?;

            map.end()
        }
    }
}
