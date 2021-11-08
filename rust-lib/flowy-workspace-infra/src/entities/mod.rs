pub mod app;
pub mod trash;
pub mod view;
pub mod workspace;

pub mod prelude {
    pub use crate::entities::{app::*, trash::*, view::*, workspace::*};
}
