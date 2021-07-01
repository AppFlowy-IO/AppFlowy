mod error;

pub type ResponseResult<T, E> = std::result::Result<crate::request::Data<T>, E>;

pub use error::*;
