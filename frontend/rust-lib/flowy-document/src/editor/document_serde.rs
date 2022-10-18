pub fn serialize_document_tree<S>(body: &Body, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut map = serializer.serialize_map(Some(3))?;
    match body {
        Body::Empty => {}
        Body::Delta(delta) => {
            map.serialize_key("delta")?;
            map.serialize_value(delta)?;
        }
    }
    map.end()
}
