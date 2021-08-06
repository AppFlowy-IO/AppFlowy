pub mod helper;

use crate::helper::{TestOp::*, *};

#[test]
fn delta_undo_insert_text() {
    let ops = vec![Insert(0, "123", 0), Undo(0), AssertOpsJson(0, r#"[]"#)];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_undo_insert_text2() {
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
