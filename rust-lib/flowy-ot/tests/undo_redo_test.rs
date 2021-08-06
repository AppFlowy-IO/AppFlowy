pub mod helper;

use crate::helper::{TestOp::*, *};

#[test]
fn delta_undo_insert() {
    let ops = vec![Insert(0, "123", 0), Undo(0), AssertOpsJson(0, r#"[]"#)];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_insert2() {
    let ops = vec![
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
