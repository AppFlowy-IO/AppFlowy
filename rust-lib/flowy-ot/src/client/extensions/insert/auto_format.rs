use crate::{
    client::{extensions::InsertExt, util::is_whitespace},
    core::{Delta, DeltaIter},
};

pub struct AutoFormatExt {}
impl InsertExt for AutoFormatExt {
    fn ext_name(&self) -> &str { std::any::type_name::<AutoFormatExt>() }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        // enter whitespace to trigger auto format
        if !is_whitespace(text) {
            return None;
        }
        let mut iter = DeltaIter::new(delta);
        if let Some(prev) = iter.next_op_with_len(index) {
            match AutoFormat::parse(prev.get_data()) {
                None => {},
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
                        None => plain_attributes(),
                        Some(op) => op.get_attributes(),
                    };

                    return Some(
                        DeltaBuilder::new()
                            .retain(index + replace_len - min(index, format_len))
                            .retain_with_attributes(format_len, format_attributes)
                            .insert_with_attributes(text, next_attributes)
                            .build(),
                    );
                },
            }
        }

        None
    }
}

use crate::core::{plain_attributes, Attribute, Attributes, DeltaBuilder};
use bytecount::num_chars;
use std::cmp::min;
use url::Url;

pub enum AutoFormatter {
    Url(Url),
}

impl AutoFormatter {
    pub fn to_attributes(&self) -> Attributes {
        match self {
            AutoFormatter::Url(url) => Attribute::Link(url.as_str()).into(),
        }
    }

    pub fn format_len(&self) -> usize {
        let s = match self {
            AutoFormatter::Url(url) => url.to_string(),
        };

        num_chars(s.as_bytes())
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
