use flowy_grid_data_model::entities::*;

#[test]
fn grid_serde_test() {
    let grid_id = "1".to_owned();
    let fields = vec![create_field("1")];
    let grid = GridMeta {
        grid_id,
        fields,
        block_metas: vec![],
    };

    let grid_1_json = serde_json::to_string(&grid).unwrap();
    let _: GridMeta = serde_json::from_str(&grid_1_json).unwrap();
    assert_eq!(
        grid_1_json,
        r#"{"id":"1","fields":[{"id":"1","name":"Text Field","desc":"","field_type":"RichText","frozen":false,"visibility":true,"width":150,"type_options":{"type_id":"","value":[]}}],"blocks":[]}"#
    )
}

#[test]
fn grid_default_serde_test() {
    let grid_id = "1".to_owned();
    let grid = GridMeta {
        grid_id,
        fields: vec![],
        block_metas: vec![],
    };

    let json = serde_json::to_string(&grid).unwrap();
    assert_eq!(json, r#"{"id":"1","fields":[],"blocks":[]}"#)
}

fn create_field(field_id: &str) -> FieldMeta {
    let mut field = FieldMeta::new("Text Field", "", FieldType::RichText);
    field.id = field_id.to_string();
    field
}

#[allow(dead_code)]
fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}
