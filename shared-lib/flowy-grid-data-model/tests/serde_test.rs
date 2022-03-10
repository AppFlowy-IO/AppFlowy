use flowy_grid_data_model::entities::*;

#[test]
fn grid_serde_test() {
    let grid_id = "1".to_owned();
    let fields = vec![create_field("1")];
    let grid = GridMeta {
        grid_id,
        fields,
        rows: vec![],
    };

    let grid_1_json = serde_json::to_string(&grid).unwrap();
    let _: Grid = serde_json::from_str(&grid_1_json).unwrap();
    assert_eq!(
        grid_1_json,
        r#"{"id":"1","fields":[{"id":"1","name":"Text Field","desc":"","field_type":"RichText","frozen":false,"visibility":true,"width":150,"type_options":{"type_id":"","value":[]}}],"rows":[]}"#
    )
}

#[test]
fn grid_default_serde_test() {
    let grid_id = "1".to_owned();
    let grid = GridMeta {
        grid_id,
        fields: vec![],
        rows: vec![],
    };

    let json = serde_json::to_string(&grid).unwrap();
    assert_eq!(json, r#"{"id":"1","fields":[],"row_orders":[]}"#)
}

fn create_field(field_id: &str) -> Field {
    Field::new(field_id, "Text Field", "", FieldType::RichText)
}

#[allow(dead_code)]
fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}
