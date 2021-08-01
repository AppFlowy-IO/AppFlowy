use flowy_ot::{
    attributes::{Attributes, AttributesBuilder},
    delta::Delta,
    operation::{OpBuilder, Operation, Retain},
};

#[test]
fn attribute_insert_merge_test() {
    let mut delta = Delta::default();
    delta.insert("123", Some(AttributesBuilder::new().bold().build()));
    delta.insert("456", Some(AttributesBuilder::new().bold().build()));
    assert_eq!(
        r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#,
        serde_json::to_string(&delta).unwrap()
    )
}
