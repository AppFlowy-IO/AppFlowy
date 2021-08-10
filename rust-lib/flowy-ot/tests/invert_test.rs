pub mod helper;
use crate::helper::{TestOp::*, *};
use flowy_ot::core::{Builder, Delta, Interval};

#[test]
fn delta_invert_no_attribute_delta() {
    let mut delta = Delta::default();
    delta.add(Builder::insert("123").build());

    let mut change = Delta::default();
    change.add(Builder::retain(3).build());
    change.add(Builder::insert("456").build());
    let undo = change.invert(&delta);

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
        AssertOpsJson(
            0,
            r#"[
            {"insert":"123456","attributes":{"bold":"true"}}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}}, 
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Invert(0, 1),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
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
            r#"[{"insert":"a","attributes":{"bold":"true"}},{"insert":"bc","attributes":
{"bold":"true","italic":"true"}},{"insert":"d","attributes":{"bold":"true"
}}]"#,
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
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertOpsJson(
            1,
            r#"[
            {"insert":"a","attributes":{"bold":"true"}},
            {"insert":"bc","attributes":{"bold":"true","italic":"true"}},
            {"insert":"d","attributes":{"bold":"true"}}
            ]"#,
        ),
        Invert(0, 1),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
    ];
    OpTester::new().run_script(ops);
}
