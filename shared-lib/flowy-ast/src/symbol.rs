use std::fmt::{self, Display};
use syn::{Ident, Path};

#[derive(Copy, Clone)]
pub struct Symbol(&'static str);
pub const PB_ATTRS: Symbol = Symbol("pb");
pub const SKIP: Symbol = Symbol("skip"); //#[pb(skip)]
pub const PB_INDEX: Symbol = Symbol("index"); //#[pb(index = "1")]
pub const PB_ONE_OF: Symbol = Symbol("one_of"); //#[pb(one_of)]
pub const DESERIALIZE_WITH: Symbol = Symbol("deserialize_with");
pub const SKIP_DESERIALIZING: Symbol = Symbol("skip_deserializing");
pub const SERIALIZE_WITH: Symbol = Symbol("serialize_with"); //#[pb(serialize_with = "...")]
pub const SKIP_SERIALIZING: Symbol = Symbol("skip_serializing"); //#[pb(skip_serializing)]
pub const PB_STRUCT: Symbol = Symbol("struct"); //#[pb(struct="some struct")]
pub const PB_ENUM: Symbol = Symbol("enum"); //#[pb(enum="some enum")]

pub const EVENT_INPUT: Symbol = Symbol("input");
pub const EVENT_OUTPUT: Symbol = Symbol("output");
pub const EVENT_IGNORE: Symbol = Symbol("ignore");
pub const EVENT: Symbol = Symbol("event");
pub const EVENT_ERR: Symbol = Symbol("event_err");

impl PartialEq<Symbol> for Ident {
    fn eq(&self, word: &Symbol) -> bool {
        self == word.0
    }
}

impl<'a> PartialEq<Symbol> for &'a Ident {
    fn eq(&self, word: &Symbol) -> bool {
        *self == word.0
    }
}

impl PartialEq<Symbol> for Path {
    fn eq(&self, word: &Symbol) -> bool {
        self.is_ident(word.0)
    }
}

impl<'a> PartialEq<Symbol> for &'a Path {
    fn eq(&self, word: &Symbol) -> bool {
        self.is_ident(word.0)
    }
}

impl Display for Symbol {
    fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str(self.0)
    }
}
