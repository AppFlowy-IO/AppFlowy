pub mod helper;
use crate::helper::{TestOp::*, *};
use flowy_ot::core::{Delta, Interval, OpBuilder};

#[test]
fn delta_invert_no_attribute_delta() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("123").build());

    let mut change = Delta::default();
    change.add(OpBuilder::retain(3).build());
    change.add(OpBuilder::insert("456").build());
    let undo = change.invert_delta(&delta);

    let new_delta = delta.compose(&change).unwrap();
    let delta_after_undo = new_delta.compose(&undo).unwrap();

    assert_eq!(delta_after_undo, delta);
}

#[test]
fn delta_invert_no_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "4567", 0),
        Invert(0, 1),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_invert_attribute_delta_with_no_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Insert(1, "4567", 0),
        Invert(0, 1),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_invert_attribute_delta_with_no_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Insert(0, "456", 3),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34","attributes":{"bold":"true","italic":"true"}},{"insert":"56","attributes":{"bold":"true"}}]"#,
        ),
        Insert(1, "abc", 0),
        Invert(0, 1),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34","attributes":{"bold":"true","italic":"true"}},{"insert":"56","attributes":{"bold":"true"}}]"#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_invert_no_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "4567", 0),
        Bold(1, Interval::new(0, 3), true),
        AssertOpsJson(
            1,
            r#"[{"insert":"456","attributes":{"bold":"true"}},{"insert":"7"}]"#,
        ),
        Invert(0, 1),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_invert_no_attribute_delta_with_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertOpsJson(
            1,
            r#"[{"insert":"a","attributes":{"bold":"true"}},{"insert":"bc","attributes":{"bold":"true","italic":"true"}},{"insert":"d","attributes":{"bold":"true"}}]"#,
        ),
        Invert(0, 1),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_invert_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Insert(0, "456", 3),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34","attributes":{"bold":"true","italic":"true"}},{"insert":"56","attributes":{"bold":"true"}}]"#,
        ),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertOpsJson(
            1,
            r#"[{"insert":"a","attributes":{"bold":"true"}},{"insert":"bc","attributes":{"bold":"true","italic":"true"}},{"insert":"d","attributes":{"bold":"true"}}]"#,
        ),
        Invert(0, 1),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34","attributes":{"bold":"true","italic":"true"}},{"insert":"56","attributes":{"bold":"true"}}]"#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_get_ops_in_interval_1() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123").build();
    let insert_b = OpBuilder::insert("4").build();

    delta.add(insert_a.clone());
    delta.add(insert_b.clone());

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 3)),
        vec![delta.ops.last().unwrap().clone()]
    );
}

#[test]
fn delta_get_ops_in_interval_2() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123").build();
    let insert_b = OpBuilder::insert("4").build();
    let insert_c = OpBuilder::insert("5").build();
    let retain_a = OpBuilder::retain(3).build();

    delta.add(insert_a.clone());
    delta.add(retain_a.clone());
    delta.add(insert_b.clone());
    delta.add(insert_c.clone());

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 3)),
        vec![insert_a.clone()]
    );

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 4)),
        vec![insert_a.clone(), retain_a.clone()]
    );

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 7)),
        vec![
            insert_a.clone(),
            retain_a.clone(),
            // insert_b and insert_c will be merged into one. insert: "45"
            delta.ops.last().unwrap().clone()
        ]
    );
}
