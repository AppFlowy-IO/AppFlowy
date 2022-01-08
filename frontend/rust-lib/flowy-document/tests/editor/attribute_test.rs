#![cfg_attr(rustfmt, rustfmt::skip)]
use crate::editor::{TestBuilder, TestOp::*};
use flowy_collaboration::document::{NewlineDoc, PlainDoc};
use lib_ot::core::{Interval, OperationTransformable, NEW_LINE, WHITESPACE, FlowyStr};
use unicode_segmentation::UnicodeSegmentation;
use lib_ot::rich_text::RichTextDelta;

#[test]
fn attributes_bold_added() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(3, 5), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"123"},
            {"insert":"45","attributes":{"bold":"true"}},
            {"insert":"6"}
            ]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_and_invert_all() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 3), false),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_and_invert_partial_suffix() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        AssertDocJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(2, 4), false),
        AssertDocJson(0, r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_and_invert_partial_suffix2() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        AssertDocJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(2, 4), false),
        AssertDocJson(0, r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#),
        Bold(0, Interval::new(2, 4), true),
        AssertDocJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_with_new_line() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "\n", 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "\n", 4),
        AssertDocJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\n\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 4),
        AssertDocJson(
            0,
            r#"[{"insert":"123","attributes":{"bold":"true"}},{"insert":"\na\n"},{"insert":"456","attributes":{"bold":"true"}},{"insert":"\n"}]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bold_added_and_invert_partial_prefix() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        AssertDocJson(0, r#"[{"insert":"1234","attributes":{"bold":"true"}}]"#),
        Bold(0, Interval::new(0, 2), false),
        AssertDocJson(0, r#"[{"insert":"12"},{"insert":"34","attributes":{"bold":"true"}}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_consecutive() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 1), true),
        AssertDocJson(0, r#"[{"insert":"1","attributes":{"bold":"true"}},{"insert":"234"}]"#),
        Bold(0, Interval::new(1, 2), true),
        AssertDocJson(0, r#"[{"insert":"12","attributes":{"bold":"true"}},{"insert":"34"}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_italic() {
    let ops = vec![
        Insert(0, "1234", 0),
        Bold(0, Interval::new(0, 4), true),
        Italic(0, Interval::new(0, 4), true),
        AssertDocJson(
            0,
            r#"[{"insert":"1234","attributes":{"italic":"true","bold":"true"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "5678", 4),
        AssertDocJson(
            0,
            r#"[{"insert":"12345678","attributes":{"bold":"true","italic":"true"}},{"insert":"\n"}]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bold_added_italic2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(0, 2), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"3456","attributes":{"bold":"true"}}]
            "#,
        ),
        Italic(0, Interval::new(4, 6), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}}]
            "#,
        ),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_italic3() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true","italic":"true"}},
            {"insert":"345","attributes":{"bold":"true"}},{"insert":"6789"}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},
            {"insert":"6789"}]
            "#,
        ),
        Bold(0, Interval::new(7, 9), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},
            {"insert":"67"},
            {"insert":"89","attributes":{"bold":"true"}}]
            "#,
        ),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_bold_added_italic_delete() {
    let ops = vec![
        Insert(0, "123456789", 0),
        Bold(0, Interval::new(0, 5), true),
        Italic(0, Interval::new(0, 2), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"345","attributes":{"bold":"true"}},{"insert":"6789"}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}}
            ,{"insert":"5","attributes":{"bold":"true"}},{"insert":"6789"}]"#,
        ),
        Bold(0, Interval::new(7, 9), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"1234","attributes":{"bold":"true","italic":"true"}},
            {"insert":"5","attributes":{"bold":"true"}},{"insert":"67"},
            {"insert":"89","attributes":{"bold":"true"}}]
            "#,
        ),
        Delete(0, Interval::new(0, 5)),
        AssertDocJson(0, r#"[{"insert":"67"},{"insert":"89","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_merge_inserted_text_with_same_attribute() {
    let ops = vec![
        InsertBold(0, "123", Interval::new(0, 3)),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        InsertBold(0, "456", Interval::new(3, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_attr_attributes_test() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertDocJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertDocJson(0, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
        AssertDocJson(1, r#"[{"insert":"1234567","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_attr_attributes_test2() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bold(0, Interval::new(0, 6), true),
        Italic(0, Interval::new(0, 2), true),
        Italic(0, Interval::new(4, 6), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true","italic":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}}]
            "#,
        ),
        InsertBold(1, "7", Interval::new(0, 1)),
        AssertDocJson(1, r#"[{"insert":"7","attributes":{"bold":"true"}}]"#),
        Transform(0, 1),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}},
            {"insert":"7","attributes":{"bold":"true"}}]
            "#,
        ),
        AssertDocJson(
            1,
            r#"[
            {"insert":"12","attributes":{"italic":"true","bold":"true"}},
            {"insert":"34","attributes":{"bold":"true"}},
            {"insert":"56","attributes":{"italic":"true","bold":"true"}},
            {"insert":"7","attributes":{"bold":"true"}}]
            "#,
        ),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_compose_attr_attributes_with_no_attr_attributes_test() {
    let expected = r#"[{"insert":"123456","attributes":{"bold":"true"}},{"insert":"7"}]"#;

    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Insert(1, "7", 0),
        AssertDocJson(1, r#"[{"insert":"7"}]"#),
        Transform(0, 1),
        AssertDocJson(0, expected),
        AssertDocJson(1, expected),
    ];
    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_replace_heading() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertDocJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_replace_trailing() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(5, 6)),
        AssertDocJson(0, r#"[{"insert":"12345","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_replace_middle() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 2)),
        AssertDocJson(0, r#"[{"insert":"3456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(2, 4)),
        AssertDocJson(0, r#"[{"insert":"34","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_replace_all() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Delete(0, Interval::new(0, 6)),
        AssertDocJson(0, r#"[]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_replace_with_text() {
    let ops = vec![
        InsertBold(0, "123456", Interval::new(0, 6)),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Replace(0, Interval::new(0, 3), "ab"),
        AssertDocJson(0, r#"[{"insert":"ab"},{"insert":"456","attributes":{"bold":"true"}}]"#),
    ];

    TestBuilder::new().run_scripts::<PlainDoc>(ops);
}

#[test]
fn attributes_header_insert_newline_at_middle() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        AssertDocJson(0, r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":1}}]"#),
        Insert(0, "\n", 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"header":1}},{"insert":"456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_header_insert_double_newline_at_middle() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        Insert(0, "\n", 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"header":1}},{"insert":"456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
        Insert(0, "\n", 4),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n\n","attributes":{"header":1}},{"insert":"456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
        Insert(0, "\n", 4),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n\n","attributes":{"header":1}},{"insert":"\n456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_header_insert_newline_at_trailing() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        Insert(0, "\n", 6),
        AssertDocJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":1}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_header_insert_double_newline_at_trailing() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        Insert(0, "\n", 6),
        Insert(0, "\n", 7),
        AssertDocJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":1}},{"insert":"\n\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_added() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io"),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_format_with_bold() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io"),
        Bold(0, Interval::new(0, 3), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"123","attributes":{"bold":"true","link":"https://appflowy.io"}},
            {"insert":"456","attributes":{"link":"https://appflowy.io"}},
            {"insert":"\n"}]
            "#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_insert_char_at_head() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io"),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 0),
        AssertDocJson(
            0,
            r#"[{"insert":"a"},{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_insert_char_at_middle() {
    let ops = vec![
        Insert(0, "1256", 0),
        Link(0, Interval::new(0, 4), "https://appflowy.io"),
        Insert(0, "34", 2),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_insert_char_at_trailing() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io"),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
        Insert(0, "a", 6),
        AssertDocJson(
            0,
            r#"[{"insert":"123456","attributes":{"link":"https://appflowy.io"}},{"insert":"a\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_insert_newline_at_middle() {
    let ops = vec![
        Insert(0, "123456", 0),
        Link(0, Interval::new(0, 6), "https://appflowy.io"),
        Insert(0, NEW_LINE, 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"},{"insert":"456","attributes":{"link":"https://appflowy.io"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_auto_format() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        AssertDocJson(0, r#"[{"insert":"https://appflowy.io\n"}]"#),
        Insert(0, WHITESPACE, site.len()),
        AssertDocJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io/"}},{"insert":" \n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_auto_format_exist() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        Link(0, Interval::new(0, site.len()), site),
        Insert(0, WHITESPACE, site.len()),
        AssertDocJson(
            0,
            r#"[{"insert":"https://appflowy.io","attributes":{"link":"https://appflowy.io/"}},{"insert":" \n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_link_auto_format_exist2() {
    let site = "https://appflowy.io";
    let ops = vec![
        Insert(0, site, 0),
        Link(0, Interval::new(0, site.len() / 2), site),
        Insert(0, WHITESPACE, site.len()),
        AssertDocJson(
            0,
            r#"[{"insert":"https://a","attributes":{"link":"https://appflowy.io"}},{"insert":"ppflowy.io \n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bullet_added() {
    let ops = vec![
        Insert(0, "12", 0),
        Bullet(0, Interval::new(0, 1), true),
        AssertDocJson(0, r#"[{"insert":"12"},{"insert":"\n","attributes":{"list":"bullet"}}]"#),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bullet_added_2() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        AssertDocJson(0, r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}}]"#),
        Insert(0, NEW_LINE, 1),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n\n","attributes":{"list":"bullet"}}]"#,
        ),
        Insert(0, "2", 2),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bullet_remove_partial() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        Insert(0, NEW_LINE, 1),
        Insert(0, "2", 2),
        Bullet(0, Interval::new(2, 3), false),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"2\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_bullet_auto_exit() {
    let ops = vec![
        Insert(0, "1", 0),
        Bullet(0, Interval::new(0, 1), true),
        Insert(0, NEW_LINE, 1),
        Insert(0, NEW_LINE, 2),
        AssertDocJson(
            0,
            r#"[{"insert":"1"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_preserve_block_when_insert_newline_inside() {
    let ops = vec![
        Insert(0, "12", 0),
        Bullet(0, Interval::new(0, 2), true),
        Insert(0, NEW_LINE, 2),
        AssertDocJson(
            0,
            r#"[{"insert":"12"},{"insert":"\n\n","attributes":{"list":"bullet"}}]"#,
        ),
        Insert(0, "34", 3),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12"},{"insert":"\n","attributes":{"list":"bullet"}},
            {"insert":"34"},{"insert":"\n","attributes":{"list":"bullet"}}
            ]"#,
        ),
        Insert(0, NEW_LINE, 3),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12"},{"insert":"\n\n","attributes":{"list":"bullet"}},
            {"insert":"34"},{"insert":"\n","attributes":{"list":"bullet"}}
            ]"#,
        ),
        Insert(0, "ab", 3),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12"},{"insert":"\n","attributes":{"list":"bullet"}},
            {"insert":"ab"},{"insert":"\n","attributes":{"list":"bullet"}},
            {"insert":"34"},{"insert":"\n","attributes":{"list":"bullet"}}
            ]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_preserve_header_format_on_merge() {
    let ops = vec![
        Insert(0, "123456", 0),
        Header(0, Interval::new(0, 6), 1),
        Insert(0, NEW_LINE, 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"header":1}},{"insert":"456"},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
        Delete(0, Interval::new(3, 4)),
        AssertDocJson(0, r#"[{"insert":"123456"},{"insert":"\n","attributes":{"header":1}}]"#),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_format_emoji() {
    let emoji_s = "👋 ";
    let s: FlowyStr = emoji_s.into();
    let len = s.utf16_size();
    assert_eq!(3, len);
    assert_eq!(2, s.graphemes(true).count());
    let ops = vec![
        Insert(0, emoji_s, 0),
        AssertDocJson(0, r#"[{"insert":"👋 \n"}]"#),
        Header(0, Interval::new(0, len), 1),
        AssertDocJson(
            0,
            r#"[{"insert":"👋 "},{"insert":"\n","attributes":{"header":1}}]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn attributes_preserve_list_format_on_merge() {
    let ops = vec![
        Insert(0, "123456", 0),
        Bullet(0, Interval::new(0, 6), true),
        Insert(0, NEW_LINE, 3),
        AssertDocJson(
            0,
            r#"[{"insert":"123"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"456"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
        Delete(0, Interval::new(3, 4)),
        AssertDocJson(
            0,
            r#"[{"insert":"123456"},{"insert":"\n","attributes":{"list":"bullet"}}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}

#[test]
fn delta_compose() {
    let mut delta = RichTextDelta::from_json(r#"[{"insert":"\n"}]"#).unwrap();
    let deltas = vec![
        RichTextDelta::from_json(r#"[{"retain":1,"attributes":{"list":"unchecked"}}]"#).unwrap(),
        RichTextDelta::from_json(r#"[{"insert":"a"}]"#).unwrap(),
        RichTextDelta::from_json(r#"[{"retain":1},{"insert":"\n","attributes":{"list":"unchecked"}}]"#).unwrap(),
        RichTextDelta::from_json(r#"[{"retain":2},{"retain":1,"attributes":{"list":""}}]"#).unwrap(),
    ];

    for d in deltas {
        delta = delta.compose(&d).unwrap();
    }
    assert_eq!(
        delta.to_json(),
        r#"[{"insert":"a"},{"insert":"\n","attributes":{"list":"unchecked"}},{"insert":"\n"}]"#
    );

    let ops = vec![
        AssertDocJson(0, r#"[{"insert":"\n"}]"#),
        Insert(0, "a", 0),
        AssertDocJson(0, r#"[{"insert":"a\n"}]"#),
        Bullet(0, Interval::new(0, 1), true),
        AssertDocJson(0, r#"[{"insert":"a"},{"insert":"\n","attributes":{"list":"bullet"}}]"#),
        Insert(0, NEW_LINE, 1),
        AssertDocJson(
            0,
            r#"[{"insert":"a"},{"insert":"\n\n","attributes":{"list":"bullet"}}]"#,
        ),
        Insert(0, NEW_LINE, 2),
        AssertDocJson(
            0,
            r#"[{"insert":"a"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n"}]"#,
        ),
    ];

    TestBuilder::new().run_scripts::<NewlineDoc>(ops);
}
