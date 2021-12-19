pub mod app;
pub mod share;
pub mod trash;
pub mod view;
pub mod workspace;

pub mod prelude {
    pub use crate::entities::{app::*, share::*, trash::*, view::*, workspace::*};
}
