use std::fmt::{self, Display};
use syn::{Ident, Path};

#[derive(Copy, Clone)]
pub struct Symbol(&'static str);

// Protobuf
pub const PB_ATTRS: Symbol = Symbol("pb");
//#[pb(skip)]
pub const SKIP: Symbol = Symbol("skip");
//#[pb(index = "1")]
pub const PB_INDEX: Symbol = Symbol("index");
//#[pb(one_of)]
pub const PB_ONE_OF: Symbol = Symbol("one_of");
//#[pb(skip_pb_deserializing = "...")]
pub const SKIP_PB_DESERIALIZING: Symbol = Symbol("skip_pb_deserializing");
//#[pb(skip_pb_serializing)]
pub const SKIP_PB_SERIALIZING: Symbol = Symbol("skip_pb_serializing");
//#[pb(serialize_pb_with = "...")]
pub const SERIALIZE_PB_WITH: Symbol = Symbol("serialize_pb_with");
//#[pb(deserialize_pb_with = "...")]
pub const DESERIALIZE_PB_WITH: Symbol = Symbol("deserialize_pb_with");
//#[pb(struct="some struct")]
pub const PB_STRUCT: Symbol = Symbol("struct");
//#[pb(enum="some enum")]
pub const PB_ENUM: Symbol = Symbol("enum");

// Event
pub const EVENT_INPUT: Symbol = Symbol("input");
pub const EVENT_OUTPUT: Symbol = Symbol("output");
pub const EVENT_IGNORE: Symbol = Symbol("ignore");
pub const EVENT: Symbol = Symbol("event");
pub const EVENT_ERR: Symbol = Symbol("event_err");

// Node
pub const NODE_ATTRS: Symbol = Symbol("node");
pub const NODES_ATTRS: Symbol = Symbol("nodes");
pub const NODE_TYPE: Symbol = Symbol("node_type");
pub const NODE_INDEX: Symbol = Symbol("index");
pub const RENAME_NODE: Symbol = Symbol("rename");
pub const CHILD_NODE_NAME: Symbol = Symbol("child_name");
pub const CHILD_NODE_INDEX: Symbol = Symbol("child_index");
pub const SKIP_NODE_ATTRS: Symbol = Symbol("skip_node_attribute");
pub const GET_NODE_VALUE_WITH: Symbol = Symbol("get_value_with");
pub const SET_NODE_VALUE_WITH: Symbol = Symbol("set_value_with");
pub const GET_VEC_ELEMENT_WITH: Symbol = Symbol("get_element_with");
pub const GET_MUT_VEC_ELEMENT_WITH: Symbol = Symbol("get_mut_element_with");
pub const WITH_CHILDREN: Symbol = Symbol("with_children");

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
