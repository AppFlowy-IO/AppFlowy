use flowy_grid_data_model::revision::*;

#[test]
fn grid_default_serde_test() {
    let grid_id = "1".to_owned();
    let grid = GridRevision::new(&grid_id);

    let json = serde_json::to_string(&grid).unwrap();
    assert_eq!(
        json,
        r#"{"grid_id":"1","fields":[],"blocks":[],"setting":{"layout":0,"filters":[],"groups":[]}}"#
    )
}
