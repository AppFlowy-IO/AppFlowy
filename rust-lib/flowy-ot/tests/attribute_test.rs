pub mod helper;

use crate::helper::{TestOp::*, *};
use flowy_ot::core::Interval;

use flowy_ot::client::extensions::{NEW_LINE, WHITESPACE};

#[test]
fn attributes_insert_text() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 3),
        AssertOpsJson(0, r#"[{"insert":"123456"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_insert_text_at_head() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 0),
        AssertOpsJson(0, r#"[{"insert":"456123"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_insert_text_at_middle() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 1),
        AssertOpsJson(0, r#"[{"insert":"145623"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_insert_text_with_attr() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(3, 5), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"123"},
            {"insert":"45","attributes":{"bold":"true"}},
            {"insert":"6"}
            ]"#,
        ),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_and_invert_all() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 3), false),
        AssertOpsJson(0, r#"[{"insert":"123"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_and_invert_partial_suffix() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_and_invert_partial_suffix2() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_with_new_line() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "\n", 3),
        AssertOpsJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "\n", 4),
        AssertOpsJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 4),
        AssertOpsJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\na\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
    ];
    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_add_bold_and_invert_partial_prefix() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_consecutive() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_italic() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        Italic(0, Interval::new(0, 4), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1234","attributes":{"italic":"true","bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "5678", 4),
        AssertOpsJson(
            0,
            r#"[{"insert":"12345678","attributes":{"bold":"true","italic":"true"}},{"insert":"\n"}]"#,
        ),
    ];
    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_add_bold_italic2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"3456","attributes":{"bold":"true"}}]
            "#,
        ),
        Italic(0, Interval::new(4, 6), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}}]
            "#,
        ),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_italic3() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true","italic":"true"}},
            {"insert":"345","attributes":{"bold":"true"}},{"insert":"6789"}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},
            {"insert":"6789"}]
            "#,
        ),
        Bold(0, Interval::new(7, 9), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},
            {"insert":"67"},
            {"insert":"89","attributes":{"bold":"true"}}]
            "#,
        ),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_add_bold_italic_delete() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"345","attributes":{"bold":"true"}},{"insert":"6789"}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}}
            ,{"insert":"5","attributes":{"bold":"true"}},{"insert":"6789"}]"#,
        ),
        Bold(0, Interval::new(7, 9), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},{"insert":"67"},
            {"insert":"89","attributes":{"bold":"true"}}]
            "#,
        ),
        Delete(0, Interval::new(0, 5)),
        AssertOpsJson(
            0,
            r#"[{"insert":"67"},{"insert":"89","attributes":{"bold":"true"}}]"#,
        ),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_merge_inserted_text_with_same_attribute() {
    let ops = vec![
        InsertBold(0, "123", Interval::new(0, 3)),
        AssertOpsJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        InsertBold(0, "456", Interval::new(3, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_attr_attributes_test() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertOpsJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertOpsJson(0, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
        AssertOpsJson(1, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_attr_attributes_test2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        Italic(0, Interval::new(0, 2), true),
        Italic(0, Interval::new(4, 6), true),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true","italic":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}}]
            "#,
        ),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertOpsJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertOpsJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}},
            {"insert":"7","attributes":{"bold":"true"}}]
            "#,
        ),
        AssertOpsJson(
            1,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}},
            {"insert":"7","attributes":{"bold":"true"}}]
            "#,
        ),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_no_attr_attributes_test() {
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
    OpTester::new().run_script(ops);
}

#[test]
fn attributes_replace_heading() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertOpsJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_replace_trailing() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(5, 6)),
        AssertOpsJson(0, r#"[{"insert":"12345","attributes":{"bold":"true"}}]"#),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_replace_middle() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertOpsJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(2, 4)),
        AssertOpsJson(0, r#"[{"insert":"34","attributes":{"bold":"true"}}]"#),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_replace_all() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 6)),
        AssertOpsJson(0, r#"[]"#),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_replace_with_text() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertOpsJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Replace(0, Interval::new(0, 3), "ab"),
        AssertOpsJson(
            0,
            r#"[{"insert":"ab"},{"insert":"456","attributes":{"bold":"true"}}]"#,
        ),
    ];

    OpTester::new().run_script(ops);
}

#[test]
fn attributes_header_insert_newline_at_middle() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1, true),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":"1"}}]"#,
        ),
        Insert(0, "\n", 3),
        AssertOpsJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"header":"1"}},{"insert":"456"},{"insert":"\n","attributes":{"header":"1"}}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_header_insert_newline_at_middle2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1, true),
        Insert(0, "\n", 3),
        AssertOpsJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"header":"1"}},{"insert":"456"},{"insert":"\n","attributes":{"header":"1"}}]"#,
        ),
        Insert(0, "\n", 4),
        AssertOpsJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n\n","attributes":{"header":"1"}},{"insert":"456"},{"insert":"\n","attributes":{"header":"1"}}]"#,
        ),
        Insert(0, "\n", 4),
        AssertOpsJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n\n","attributes":{"header":"1"}},{"insert":"\n456"},{"insert":"\n","attributes":{"header":"1"}}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_header_insert_newline_at_trailing() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1, true),
        Insert(0, "\n", 6),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":"1"}},{"insert":"\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_add_link() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io", true),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_link_insert_char_at_head() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io", true),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 0),
        AssertOpsJson(
            0,
            r#"[{"insert":"a"},{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_link_insert_char_at_middle() {
    let ops = vec![
        Insert(0, "1256", 0),
        Link(0, Interval::new(0, 4), "https://appflowy.io", true),
        Insert(0, "34", 2),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_link_insert_char_at_trailing() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io", true),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 6),
        AssertOpsJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"a\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_link_insert_newline_at_middle() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io", true),
        Insert(0, NEW_LINE, 3),
        AssertOpsJson(
            0,
            r#"[{"insert":"123","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"},{"insert":"456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_auto_format_link() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        AssertOpsJson(0, r#"[{"insert":"https://appflowy.io\n"}]"#),
        Insert(0, WHITESPACE, site.len()),
        AssertOpsJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io/"}},{"insert":" \n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_auto_format_exist_link() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        Link(0, Interval::new(0, site.len()), site, true),
        Insert(0, WHITESPACE, site.len()),
        AssertOpsJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io/"}},{"insert":" \n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_auto_format_exist_link2() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        Link(0, Interval::new(0, site.len() / 2), site, true),
        Insert(0, WHITESPACE, site.len()),
        AssertOpsJson(
            0,
            r#"[{"insert":"https://a","attributes":{"link":"https://appflowy.io"}},{"insert":"ppflowy.io \n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_add_bullet() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        AssertOpsJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"bullet":"true"}}]"#,
        ),
        Insert(0, NEW_LINE, 1),
        Insert(0, "2", 2),
        AssertOpsJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"bullet":"true"}},{"insert":"2"},{"insert":"\n","attributes":{"bullet":"true"}}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}

#[test]
fn attributes_un_bullet_one() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        Insert(0, NEW_LINE, 1),
        Insert(0, "2", 2),
        Bullet(0, Interval::new(2, 3), false),
        AssertOpsJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"bullet":"true"}},{"insert":"2\n"}]"#,
        ),
    ];

    OpTester::new().run_script_with_newline(ops);
}
