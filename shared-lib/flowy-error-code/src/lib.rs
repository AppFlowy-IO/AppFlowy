pub mod client;

#[cfg(feature = "adaptor_server_error")]
pub mod server {
    pub use http_error_code::*;

    use crate::client::ErrorCode as ClientErrorCode;
    use http_error_code::ErrorCode as ServerErrorCode;

    impl std::convert::From<ServerErrorCode> for ClientErrorCode {
        fn from(code: ServerErrorCode) -> Self {
            match code {
                ServerErrorCode::UserUnauthorized => ClientErrorCode::UserUnauthorized,
                ServerErrorCode::PasswordNotMatch => ClientErrorCode::PasswordNotMatch,
                ServerErrorCode::RecordNotFound => ClientErrorCode::RecordNotFound,
                ServerErrorCode::ConnectRefused | ServerErrorCode::ConnectTimeout | ServerErrorCode::ConnectClose => {
                    ClientErrorCode::HttpServerConnectError
                }
                _ => ClientErrorCode::Internal,
            }
        }
    }
}
