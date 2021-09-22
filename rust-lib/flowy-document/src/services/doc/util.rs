use flowy_ot::core::{NEW_LINE, WHITESPACE};

#[inline]
pub fn find_newline(s: &str) -> Option<usize> {
    match s.find(NEW_LINE) {
        None => None,
        Some(line_break) => Some(line_break),
    }
}

#[inline]
pub fn is_newline(s: &str) -> bool { s == NEW_LINE }

#[inline]
pub fn is_whitespace(s: &str) -> bool { s == WHITESPACE }

#[inline]
pub fn contain_newline(s: &str) -> bool { s.contains(NEW_LINE) }
