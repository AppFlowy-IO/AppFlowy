use crate::core::{Delta, DeltaIterator};
use crate::rich_text::{is_block, RichTextAttributeKey, RichTextAttributeValue, RichTextAttributes};
use std::collections::HashMap;

const LINEFEEDASCIICODE: i32 = 0x0A;

#[cfg(test)]
mod tests {
    use crate::codec::markdown::markdown_encoder::markdown_encoder;
    use crate::rich_text::RichTextDelta;

    #[test]
    fn markdown_encoder_header_1_test() {
        let json = r#"[{"insert":"header 1"},{"insert":"\n","attributes":{"header":1}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "# header 1\n");
    }

    #[test]
    fn markdown_encoder_header_2_test() {
        let json = r#"[{"insert":"header 2"},{"insert":"\n","attributes":{"header":2}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "## header 2\n");
    }

    #[test]
    fn markdown_encoder_header_3_test() {
        let json = r#"[{"insert":"header 3"},{"insert":"\n","attributes":{"header":3}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "### header 3\n");
    }

    #[test]
    fn markdown_encoder_bold_italics_underlined_test() {
        let json = r#"[{"insert":"bold","attributes":{"bold":true}},{"insert":" "},{"insert":"italics","attributes":{"italic":true}},{"insert":" "},{"insert":"underlined","attributes":{"underline":true}},{"insert":" "},{"insert":"\n","attributes":{"header":3}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "### **bold** _italics_ <u>underlined</u> \n");
    }
    #[test]
    fn markdown_encoder_strikethrough_highlight_test() {
        let json = r##"[{"insert":"strikethrough","attributes":{"strike":true}},{"insert":" "},{"insert":"highlighted","attributes":{"background":"#ffefe3"}},{"insert":"\n"}]"##;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "~~strikethrough~~ <mark>highlighted</mark>\n");
    }

    #[test]
    fn markdown_encoder_numbered_list_test() {
        let json = r#"[{"insert":"numbered list\nitem 1"},{"insert":"\n","attributes":{"list":"ordered"}},{"insert":"item 2"},{"insert":"\n","attributes":{"list":"ordered"}},{"insert":"item3"},{"insert":"\n","attributes":{"list":"ordered"}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "numbered list\n\n1. item 1\n1. item 2\n1. item3\n");
    }

    #[test]
    fn markdown_encoder_bullet_list_test() {
        let json = r#"[{"insert":"bullet list\nitem1"},{"insert":"\n","attributes":{"list":"bullet"}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "bullet list\n\n* item1\n");
    }

    #[test]
    fn markdown_encoder_check_list_test() {
        let json = r#"[{"insert":"check list\nchecked"},{"insert":"\n","attributes":{"list":"checked"}},{"insert":"unchecked"},{"insert":"\n","attributes":{"list":"unchecked"}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "check list\n\n- [x] checked\n\n- [ ] unchecked\n");
    }

    #[test]
    fn markdown_encoder_code_test() {
        let json = r#"[{"insert":"code this "},{"insert":"print(\"hello world\")","attributes":{"code":true}},{"insert":"\n"}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "code this `print(\"hello world\")`\n");
    }

    #[test]
    fn markdown_encoder_quote_block_test() {
        let json = r#"[{"insert":"this is a quote block"},{"insert":"\n","attributes":{"blockquote":true}}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "> this is a quote block\n");
    }

    #[test]
    fn markdown_encoder_link_test() {
        let json = r#"[{"insert":"appflowy","attributes":{"link":"https://www.appflowy.io/"}},{"insert":"\n"}]"#;
        let delta = RichTextDelta::from_json(json).unwrap();
        let md = markdown_encoder(&delta);
        assert_eq!(md, "[appflowy](https://www.appflowy.io/)\n");
    }
}

struct Attribute {
    key: RichTextAttributeKey,
    value: RichTextAttributeValue,
}

pub fn markdown_encoder(delta: &Delta<RichTextAttributes>) -> String {
    let mut markdown_buffer = String::new();
    let mut line_buffer = String::new();
    let mut current_inline_style = RichTextAttributes::default();
    let mut current_block_lines: Vec<String> = Vec::new();
    let mut iterator = DeltaIterator::new(delta);
    let mut current_block_style: Option<Attribute> = None;

    while iterator.has_next() {
        let operation = iterator.next().unwrap();
        let operation_data = operation.get_data();
        if !operation_data.contains("\n") {
            handle_inline(
                &mut current_inline_style,
                &mut line_buffer,
                String::from(operation_data),
                operation.get_attributes(),
            )
        } else {
            handle_line(
                &mut line_buffer,
                &mut markdown_buffer,
                String::from(operation_data),
                operation.get_attributes(),
                &mut current_block_style,
                &mut current_block_lines,
                &mut current_inline_style,
            )
        }
    }
    handle_block(&mut current_block_style, &mut current_block_lines, &mut markdown_buffer);

    markdown_buffer
}

fn handle_inline(
    current_inline_style: &mut RichTextAttributes,
    buffer: &mut String,
    mut text: String,
    attributes: RichTextAttributes,
) {
    let mut marked_for_removal: HashMap<RichTextAttributeKey, RichTextAttributeValue> = HashMap::new();

    for key in current_inline_style
        .clone()
        .keys()
        .collect::<Vec<&RichTextAttributeKey>>()
        .into_iter()
        .rev()
    {
        if is_block(key) {
            continue;
        }

        if attributes.contains_key(key) {
            continue;
        }

        let padding = trim_right(buffer);
        write_attribute(buffer, key, current_inline_style.get(key).unwrap(), true);
        if !padding.is_empty() {
            buffer.push_str(&padding)
        }
        marked_for_removal.insert(key.clone(), current_inline_style.get(key).unwrap().clone());
    }

    for (marked_for_removal_key, marked_for_removal_value) in &marked_for_removal {
        current_inline_style.retain(|inline_style_key, inline_style_value| {
            inline_style_key != marked_for_removal_key && inline_style_value != marked_for_removal_value
        })
    }

    for (key, value) in attributes.iter() {
        if is_block(key) {
            continue;
        }
        if current_inline_style.contains_key(key) {
            continue;
        }
        let original_text = text.clone();
        text = text.trim_start().to_string();
        let padding = " ".repeat(original_text.len() - text.len());
        if !padding.is_empty() {
            buffer.push_str(&padding)
        }
        write_attribute(buffer, key, value, false)
    }

    buffer.push_str(&text);
    *current_inline_style = attributes;
}

fn trim_right(buffer: &mut String) -> String {
    let text = buffer.clone();
    if !text.ends_with(" ") {
        return String::from("");
    }
    let result = text.trim_end();
    buffer.clear();
    buffer.push_str(result);
    " ".repeat(text.len() - result.len())
}

fn write_attribute(buffer: &mut String, key: &RichTextAttributeKey, value: &RichTextAttributeValue, close: bool) {
    match key {
        RichTextAttributeKey::Bold => buffer.push_str("**"),
        RichTextAttributeKey::Italic => buffer.push_str("_"),
        RichTextAttributeKey::Underline => {
            if close {
                buffer.push_str("</u>")
            } else {
                buffer.push_str("<u>")
            }
        }
        RichTextAttributeKey::StrikeThrough => {
            if close {
                buffer.push_str("~~")
            } else {
                buffer.push_str("~~")
            }
        }
        RichTextAttributeKey::Link => {
            if close {
                buffer.push_str(format!("]({})", value.0.as_ref().unwrap()).as_str())
            } else {
                buffer.push_str("[")
            }
        }
        RichTextAttributeKey::Background => {
            if close {
                buffer.push_str("</mark>")
            } else {
                buffer.push_str("<mark>")
            }
        }
        RichTextAttributeKey::CodeBlock => {
            if close {
                buffer.push_str("\n```")
            } else {
                buffer.push_str("```\n")
            }
        }
        RichTextAttributeKey::InlineCode => {
            if close {
                buffer.push_str("`")
            } else {
                buffer.push_str("`")
            }
        }
        _ => {}
    }
}

fn handle_line(
    buffer: &mut String,
    markdown_buffer: &mut String,
    data: String,
    attributes: RichTextAttributes,
    current_block_style: &mut Option<Attribute>,
    current_block_lines: &mut Vec<String>,
    current_inline_style: &mut RichTextAttributes,
) {
    let mut span = String::new();
    for c in data.chars() {
        if (c as i32) == LINEFEEDASCIICODE {
            if !span.is_empty() {
                handle_inline(current_inline_style, buffer, span.clone(), attributes.clone());
            }
            handle_inline(
                current_inline_style,
                buffer,
                String::from(""),
                RichTextAttributes::default(),
            );

            let line_block_key = attributes.keys().find(|key| {
                if is_block(*key) {
                    return true;
                } else {
                    return false;
                }
            });

            match (line_block_key, &current_block_style) {
                (Some(line_block_key), Some(current_block_style))
                    if *line_block_key == current_block_style.key
                        && *attributes.get(line_block_key).unwrap() == current_block_style.value =>
                {
                    current_block_lines.push(buffer.clone());
                }
                (None, None) => {
                    current_block_lines.push(buffer.clone());
                }
                _ => {
                    handle_block(current_block_style, current_block_lines, markdown_buffer);
                    current_block_lines.clear();
                    current_block_lines.push(buffer.clone());

                    match line_block_key {
                        None => *current_block_style = None,
                        Some(line_block_key) => {
                            *current_block_style = Some(Attribute {
                                key: line_block_key.clone(),
                                value: attributes.get(line_block_key).unwrap().clone(),
                            })
                        }
                    }
                }
            }
            buffer.clear();
            span.clear();
        } else {
            span.push(c);
        }
    }
    if !span.is_empty() {
        handle_inline(current_inline_style, buffer, span.clone(), attributes)
    }
}

fn handle_block(
    block_style: &mut Option<Attribute>,
    current_block_lines: &mut Vec<String>,
    markdown_buffer: &mut String,
) {
    if current_block_lines.is_empty() {
        return;
    }
    if !markdown_buffer.is_empty() {
        markdown_buffer.push('\n')
    }

    match block_style {
        None => {
            markdown_buffer.push_str(&current_block_lines.join("\n"));
            markdown_buffer.push('\n');
        }
        Some(block_style) if block_style.key == RichTextAttributeKey::CodeBlock => {
            write_attribute(markdown_buffer, &block_style.key, &block_style.value, false);
            markdown_buffer.push_str(&current_block_lines.join("\n"));
            write_attribute(markdown_buffer, &block_style.key, &block_style.value, true);
            markdown_buffer.push('\n');
        }
        Some(block_style) => {
            for line in current_block_lines {
                write_block_tag(markdown_buffer, &block_style, false);
                markdown_buffer.push_str(line);
                markdown_buffer.push('\n');
            }
        }
    }
}

fn write_block_tag(buffer: &mut String, block: &Attribute, close: bool) {
    if close {
        return;
    }

    if block.key == RichTextAttributeKey::BlockQuote {
        buffer.push_str("> ");
    } else if block.key == RichTextAttributeKey::List {
        if block.value.0.as_ref().unwrap().eq("bullet") {
            buffer.push_str("* ");
        } else if block.value.0.as_ref().unwrap().eq("checked") {
            buffer.push_str("- [x] ");
        } else if block.value.0.as_ref().unwrap().eq("unchecked") {
            buffer.push_str("- [ ] ");
        } else if block.value.0.as_ref().unwrap().eq("ordered") {
            buffer.push_str("1. ");
        } else {
            buffer.push_str("* ");
        }
    } else if block.key == RichTextAttributeKey::Header {
        if block.value.0.as_ref().unwrap().eq("1") {
            buffer.push_str("# ");
        } else if block.value.0.as_ref().unwrap().eq("2") {
            buffer.push_str("## ");
        } else if block.value.0.as_ref().unwrap().eq("3") {
            buffer.push_str("### ");
        } else if block.key == RichTextAttributeKey::List {
        }
    }
}
