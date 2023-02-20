#![allow(clippy::module_inception)]
mod document;
mod document_serde;
mod editor;
mod queue;

pub use document::*;
pub use document_serde::*;
pub use editor::*;

#[inline]
// Return the read me document content
pub fn initial_read_me() -> String {
  let document_content = include_str!("READ_ME.json");
  return document_content.to_string();
}
