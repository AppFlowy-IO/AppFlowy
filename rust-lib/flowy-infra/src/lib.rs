#[allow(deprecated, clippy::large_enum_variant)]
mod errors;
pub mod sqlite;

pub use errors::{Error, ErrorKind, Result};

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
