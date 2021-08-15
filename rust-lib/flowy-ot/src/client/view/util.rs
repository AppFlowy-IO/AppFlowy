use crate::client::view::NEW_LINE;

pub fn find_newline(s: &str) -> Option<usize> {
    match s.find(NEW_LINE) {
        None => None,
        Some(line_break) => Some(line_break),
    }
}
