pub mod doc;
pub mod parser;
pub mod revision;
pub mod ws;

pub mod prelude {
    pub use crate::entities::{doc::*, parser::*, revision::*, ws::*};
}
