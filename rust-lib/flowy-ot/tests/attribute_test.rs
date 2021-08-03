pub mod helper;

use crate::helper::{MergeTestOp::*, *};
use flowy_ot::core::Interval;

#[test]
fn delta_insert_text() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 3),
        AssertOpsJson(0, r#"[{"insert":"123456"}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_insert_text_at_head() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 0),
        AssertOpsJson(0, r#"[{"insert":"456123"}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_insert_text_at_middle() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 1),
        AssertOpsJson(0, r#"[{"insert":"145623"}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_insert_text_with_attr() {
    let ops = vec![
        Insert(0, "145", 0),
        Insert(0, "23", 1),
        Bold(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"345"}]"#,
        ),
        Insert(0, "abc", 1),
        AssertOpsJson(
            0,
            r#"[{"insert":"1abc2","attributes":{"bold":"true"}},{"insert":"345"}]"#,
        ),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_and_invert_all() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 3), false),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_and_invert_partial_suffix() {
    let ops = vec![
        Insert(0, "1234", 0),
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
fn delta_add_bold_and_invert_partial_suffix2() {
    let ops = vec![
        Insert(0, "1234", 0),
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
fn delta_add_bold_and_invert_partial_prefix() {
    let ops = vec![
        Insert(0, "1234", 0),
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
fn delta_add_bold_consecutive() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 1), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1","attributes":{"bold":"true"}},{"insert":"234"}]"#,
        ),
        Bold(0, Interval::new(1, 2), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#,
        ),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
#[should_panic]
fn delta_add_bold_empty_str() {
    let ops = vec![Bold(0, Interval::new(0, 4), true)];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_italic() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        Italic(0, Interval::new(0, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"italic":"true","bold":"true"}}]"#,
        ),
        Insert(0, "5678", 4),
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
fn delta_add_bold_italic2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"italic":"true","bold":"true"}},{"insert":"3456","attributes":{"bold":"true"}}]"#,
        ),
        Italic(0, Interval::new(4, 6), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true","italic":"true"}},{"insert":"34","attributes":{"bold":"true"}},{"insert":"56","attributes":{"italic":"true"}}]"#,
        ),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_italic3() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true","italic":"true"}},{"insert":"345","attributes":{"bold":"true"}},{"insert":"6789"}]"#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"bold":"true","italic":"true"}},{"insert":"5","attributes":{"bold":"true"}},{"insert":"6789"}]"#,
        ),
        Bold(0, Interval::new(7, 9), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"bold":"true","italic":"true"}},{"insert":"5","attributes":{"bold":"true"}},{"insert":"67"},{"insert":"89","attributes":{"bold":"true"}}]"#,
        ),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_add_bold_italic_delete() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        Italic(0, Interval::new(2, 4), true),
        Bold(0, Interval::new(7, 9), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"bold":"true","italic":"true"}},{"insert":"5","attributes":{"bold":"true"}},{"insert":"67"},{"insert":"89","attributes":{"bold":"true"}}]"#,
        ),
        Delete(0, Interval::new(0, 5)),
        AssertOpsJson(
            0,
            r#"[{"insert":"67","attributes":{"bold":"true"}},{"insert":"89"}]"#,
        ),
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

#[test]
fn delta_compose_attr_delta_with_attr_delta_test2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        Italic(0, Interval::new(0, 2), true),
        Italic(0, Interval::new(4, 6), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"bold":"true","italic":"true"}},{"insert":"34","attributes":{"bold":"true"}},{"insert":"56","attributes":{"italic":"true"}}]"#,
        ),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertOpsJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertOpsJson(
            0,
            r#"[{"insert":"12","attributes":{"italic":"true","bold":"true"}},{"insert":"34","attributes":{"bold":"true"}},{"insert":"56","attributes":{"italic":"true"}},{"insert":"7","attributes":{"bold":"true"}}]"#,
        ),
        AssertOpsJson(
            1,
            r#"[{"insert":"12","attributes":{"italic":"true","bold":"true"}},{"insert":"34","attributes":{"bold":"true"}},{"insert":"56","attributes":{"italic":"true"}},{"insert":"7","attributes":{"bold":"true"}}]"#,
        ),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_compose_attr_delta_with_no_attr_delta_test() {
    let expected = r#"[{"insert":"123456","attributes":{"bold":"true"}},{"insert":"7"}]"#;
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Insert(1, "7", 0),
        AssertOpsJson(1, r#"[{"insert":"7"}]"#),
        Transform(0, 1),
        AssertOpsJson(0, expected),
        AssertOpsJson(1, expected),
    ];
    MergeTest::new().run_script(ops);
}

#[test]
fn delta_delete_heading() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertOpsJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_delete_trailing() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(5, 6)),
        AssertOpsJson(0, r#"[{"insert":"12345","attributes":{"bold":"true"}}]"#),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_delete_middle() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertOpsJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(2, 4)),
        AssertOpsJson(0, r#"[{"insert":"34","attributes":{"bold":"true"}}]"#),
    ];

    MergeTest::new().run_script(ops);
}

#[test]
fn delta_delete_all() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 6)),
        AssertOpsJson(0, r#"[]"#),
    ];

    MergeTest::new().run_script(ops);
}
