use crate::{client_document::InsertExt, util::is_whitespace};
use lib_ot::core::AttributeHashMap;
use lib_ot::{
    core::{count_utf16_code_units, OperationBuilder, OperationIterator},
    text_delta::{empty_attributes, BuildInTextAttribute, TextOperations},
};
use std::cmp::min;
use url::Url;

pub struct AutoFormatExt {}
impl InsertExt for AutoFormatExt {
    fn ext_name(&self) -> &str {
        "AutoFormatExt"
    }

    fn apply(&self, delta: &TextOperations, replace_len: usize, text: &str, index: usize) -> Option<TextOperations> {
        // enter whitespace to trigger auto format
        if !is_whitespace(text) {
            return None;
        }
        let mut iter = OperationIterator::new(delta);
        if let Some(prev) = iter.next_op_with_len(index) {
            match AutoFormat::parse(prev.get_data()) {
                None => {}
                Some(formatter) => {
                    let mut new_attributes = prev.get_attributes();

                    // format_len should not greater than index. The url crate will add "/" to the
                    // end of input string that causes the format_len greater than the input string
                    let format_len = min(index, formatter.format_len());

                    let format_attributes = formatter.to_attributes();
                    format_attributes.iter().for_each(|(k, v)| {
                        if !new_attributes.contains_key(k) {
                            new_attributes.insert(k.clone(), v.clone());
                        }
                    });

                    let next_attributes = match iter.next_op() {
                        None => empty_attributes(),
                        Some(op) => op.get_attributes(),
                    };

                    return Some(
                        OperationBuilder::new()
                            .retain(index + replace_len - min(index, format_len))
                            .retain_with_attributes(format_len, format_attributes)
                            .insert_with_attributes(text, next_attributes)
                            .build(),
                    );
                }
            }
        }

        None
    }
}

pub enum AutoFormatter {
    Url(Url),
}

impl AutoFormatter {
    pub fn to_attributes(&self) -> AttributeHashMap {
        match self {
            AutoFormatter::Url(url) => BuildInTextAttribute::Link(url.as_str()).into(),
        }
    }

    pub fn format_len(&self) -> usize {
        let s = match self {
            AutoFormatter::Url(url) => url.to_string(),
        };

        count_utf16_code_units(&s)
    }
}

pub struct AutoFormat {}
impl AutoFormat {
    fn parse(s: &str) -> Option<AutoFormatter> {
        if let Ok(url) = Url::parse(s) {
            return Some(AutoFormatter::Url(url));
        }

        None
    }
}
