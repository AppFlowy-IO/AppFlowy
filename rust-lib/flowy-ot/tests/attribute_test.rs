pub mod helper;

use crate::{
    helper::{MergeTestOp::*, *},
    MergeTestOp::*,
};
use flowy_ot::{
    attributes::{Attributes, AttrsBuilder},
    delta::Delta,
    interval::Interval,
    operation::{OpBuilder, Operation, Retain},
};

#[test]
fn delta_add_bold_attr1() {
    let ops = vec![
        Insert(0, "123"),
        Bold(0, Interval::new(0, 3), true),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 3), false),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_attr2() {
    let ops = vec![
        Insert(0, "1234"),
        Bold(0, Interval::new(0, 4), true),
        AssertOpsJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(2, 4), false),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#,
        ),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_attr3() {
    let ops = vec![
        Insert(0, "1234"),
        Bold(0, Interval::new(0, 4), true),
        AssertOpsJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 2), false),
        AssertOpsJson(
            0,
            r#"[{"insert":"12"},{"insert":"34","attributes":{"bold":"true"}}]"#,
        ),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_italic() {
    let ops = vec![
        Insert(0, "1234"),
        Bold(0, Interval::new(0, 4), true),
        Italic(0, Interval::new(0, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"italic":"true","bold":"true"}}]"#,
        ),
        Insert(0, "5678"),
        AssertOpsJson(
            0,
            r#"[{"insert":"12345678","attributes":{"italic":"true","bold":"true"}}]"#,
        ),
        Italic(0, Interval::new(4, 6), false),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"italic":"true","bold":"true"}},{"insert":"56"},{"insert":"78","attributes":{"bold":"true","italic":"true"}}]"#,
        ),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_attr_and_invert() {
    let ops = vec![
        Insert(0, "1234"),
        Bold(0, Interval::new(0, 4), true),
        AssertOpsJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(2, 4), false),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#,
        ),
        Bold(0, Interval::new(2, 4), true),
        AssertOpsJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_merge_inserted_text_with_same_attribute() {
    let ops = vec![
        InsertBold(0, "123", Interval::new(0, 3)),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        InsertBold(0, "456", Interval::new(3, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_compose_attr_delta_with_no_attr_delta_test() {
    let expected = r#"[{"insert":"123456","attributes":{"bold":"true"}},{"insert":"7"}]"#;
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Insert(1, "7"),
        AssertOpsJson(1, r#"[{"insert":"7"}]"#),
        Transform(0, 1),
        AssertOpsJson(0, expected),
        AssertOpsJson(1, expected),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_compose_attr_delta_with_attr_delta_test() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertOpsJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertOpsJson(0, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
        AssertOpsJson(1, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
    ];

    MergeTest::new().run_script(ops);
}
