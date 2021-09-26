use crate::editor::{TestBuilder, TestOp::*};
use flowy_document::services::doc::{FlowyDoc, PlainDoc, RECORD_THRESHOLD};
use flowy_ot::core::{Interval, NEW_LINE, WHITESPACE};

#[test]
fn history_insert_undo() {
    let ops = vec![Insert(0, "123", 0), Undo(0), AssertDocJson(0, r#"[{"insert":"\n"}]"#)];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_insert_undo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Insert(0, "456", 0),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_insert_redo() {
    let ops = vec![
        Insert(0, "123", 0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_insert_redo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Insert(0, "456", 3),
        Wait(RECORD_THRESHOLD),
        AssertStr(0, "123456\n"),
        AssertDocJson(0, r#"[{"insert":"123456\n"}]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
        Redo(0),
        AssertDocJson(0, r#"[{"insert":"123456\n"}]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bold_undo() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bold_undo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bold_redo() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        AssertDocJson(0, r#" [{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bold_redo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Bold(0, Interval::new(0, 3), true),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123\n"}]"#),
        Redo(0),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_delete_undo() {
    let ops = vec![
        Insert(0, "123", 0),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
        Delete(0, Interval::new(0, 3)),
        AssertDocJson(0, r#"[]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn history_delete_undo_2() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Delete(0, Interval::new(0, 1)),
        AssertDocJson(
            0,
            r#"[
            {"insert":"23","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_delete_undo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Bold(0, Interval::new(0, 3), true),
        Wait(RECORD_THRESHOLD),
        Delete(0, Interval::new(0, 1)),
        AssertDocJson(
            0,
            r#"[
            {"insert":"23","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
        Undo(0),
        AssertDocJson(
            0,
            r#"[
            {"insert":"123","attributes":{"bold":"true"}},
            {"insert":"\n"}]
            "#,
        ),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_delete_redo() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Delete(0, Interval::new(0, 3)),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Undo(0),
        Redo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_replace_undo() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Replace(0, Interval::new(0, 2), "ab"),
        AssertDocJson(
            0,
            r#"[
            {"insert":"ab"},
            {"insert":"3","attributes":{"bold":"true"}},{"insert":"\n"}]
            "#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_replace_undo_with_lagging() {
    let ops = vec![
        Insert(0, "123", 0),
        Wait(RECORD_THRESHOLD),
        Bold(0, Interval::new(0, 3), true),
        Wait(RECORD_THRESHOLD),
        Replace(0, Interval::new(0, 2), "ab"),
        AssertDocJson(
            0,
            r#"[
            {"insert":"ab"},
            {"insert":"3","attributes":{"bold":"true"}},{"insert":"\n"}]
            "#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"}]"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_replace_redo() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Replace(0, Interval::new(0, 2), "ab"),
        Undo(0),
        Redo(0),
        AssertDocJson(
            0,
            r#"[
            {"insert":"ab"},
            {"insert":"3","attributes":{"bold":"true"}},{"insert":"\n"}]
            "#,
        ),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_header_added_undo() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        Insert(0, "\n", 3),
        Insert(0, "\n", 4),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n\n","attributes":{"header":1}},{"insert":"456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_link_added_undo() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        Wait(RECORD_THRESHOLD),
        Link(0, Interval::new(0, site.len()), site),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"https://appflowy.io\n"}]"#),
        Redo(0),
        AssertDocJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_link_auto_format_undo_with_lagging() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        AssertDocJson(0, r#"[{"insert":"https://appflowy.io\n"}]"#),
        Wait(RECORD_THRESHOLD),
        Insert(0, WHITESPACE, site.len()),
        AssertDocJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io/"}},{"insert":" \n"}]"#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"https://appflowy.io\n"}]"#),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bullet_undo() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        Insert(0, NEW_LINE, 1),
        Insert(0, "2", 2),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_bullet_undo_with_lagging() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        Wait(RECORD_THRESHOLD),
        Insert(0, NEW_LINE, 1),
        Insert(0, "2", 2),
        Wait(RECORD_THRESHOLD),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}}]"#),
        Undo(0),
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Redo(0),
        Redo(0),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}

#[test]
fn history_undo_attribute_on_merge_between_line() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bullet(0, Interval::new(0, 6), true),
        Wait(RECORD_THRESHOLD),
        Insert(0, NEW_LINE, 3),
        Wait(RECORD_THRESHOLD),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"456"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
        Delete(0, Interval::new(3, 4)), // delete the newline
        AssertDocJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
        Undo(0),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"456"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
    ];

    TestBuilder::new().run_script::<FlowyDoc>(ops);
}
