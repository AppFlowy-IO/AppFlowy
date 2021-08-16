use crate::{
    client::extensions::{NEW_LINE, WHITESPACE},
    core::Operation,
};

#[inline]
pub fn find_newline(s: &str) -> Option<usize> {
    match s.find(NEW_LINE) {
        None => None,
        Some(line_break) => Some(line_break),
    }
}

#[derive(PartialEq, Eq)]
pub enum OpNewline {
    Start,
    End,
    Contain,
    Equal,
    NotFound,
}

impl OpNewline {
    pub fn parse(op: &Operation) -> OpNewline {
        let s = op.get_data();

        if s == NEW_LINE {
            return OpNewline::Equal;
        }

        if s.starts_with(NEW_LINE) {
            return OpNewline::Start;
        }

        if s.ends_with(NEW_LINE) {
            return OpNewline::End;
        }

        if s.contains(NEW_LINE) {
            return OpNewline::Contain;
        }

        OpNewline::NotFound
    }

    pub fn is_start(&self) -> bool { self == &OpNewline::Start }

    pub fn is_end(&self) -> bool { self == &OpNewline::End }

    pub fn is_not_found(&self) -> bool { self == &OpNewline::NotFound }

    pub fn is_contain(&self) -> bool {
        self.is_start() || self.is_end() || self.is_equal() || self == &OpNewline::Contain
    }

    pub fn is_equal(&self) -> bool { self == &OpNewline::Equal }
}

#[inline]
pub fn is_op_contains_newline(op: &Operation) -> bool { contain_newline(op.get_data()) }

#[inline]
pub fn is_newline(s: &str) -> bool { s == NEW_LINE }

#[inline]
pub fn is_whitespace(s: &str) -> bool { s == WHITESPACE }

#[inline]
pub fn contain_newline(s: &str) -> bool { s.contains(NEW_LINE) }
