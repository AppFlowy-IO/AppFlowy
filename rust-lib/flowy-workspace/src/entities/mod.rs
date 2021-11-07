pub mod app;
pub mod trash;
pub mod view;
pub mod workspace;

pub mod parser {
    pub use crate::entities::{app::parser::*, trash::parser::*, view::parser::*, workspace::parser::*};
}
