use flowy_grid_data_model::entities::*;

#[test]
fn grid_default_serde_test() {
    let grid_id = "1".to_owned();
    let grid = GridMeta {
        grid_id,
        fields: vec![],
        blocks: vec![],
    };

    let json = serde_json::to_string(&grid).unwrap();
    assert_eq!(json, r#"{"grid_id":"1","fields":[],"blocks":[]}"#)
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
