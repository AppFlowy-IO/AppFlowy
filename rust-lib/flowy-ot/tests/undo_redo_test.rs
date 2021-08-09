pub mod helper;

use crate::helper::{TestOp::*, *};
use flowy_ot::core::Interval;

#[test]
fn delta_undo_insert() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_insert2() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Insert(0, "456", 0),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_redo_insert() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_redo_insert2() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Insert(0, "456", 3),
        AssertStr(0, "123456\n"),
        AssertOpsJson(0, r#"[{"insert":"123456\n"}]"#),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
        Redo(0),
        AssertOpsJson(0, r#"[{"insert":"123456\n"}]"#),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_attributes() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_redo_attributes() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertOpsJson(0, r#"[{"insert":"123\n"}]"#),
        Redo(0),
        AssertOpsJson(
            0,
            r#" [{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_delete() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Delete(0, Interval::new(0, 3)),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
        Undo(0),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"123","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_delete2() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Delete(0, Interval::new(0, 1)),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"23","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
        Undo(0),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"123","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_redo_delete() {
    let ops = vec![
        Insert(0, "\n", 0),
        Insert(0, "123", 0),
        Delete(0, Interval::new(0, 3)),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
        Undo(0),
        Redo(0),
        AssertOpsJson(0, r#"[{"insert":"\n"}]"#),
    ];
    OpTester::new().run_script(ops);
}
