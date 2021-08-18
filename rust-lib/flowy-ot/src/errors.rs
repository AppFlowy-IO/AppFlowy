use std::{error::Error, fmt};

#[derive(Clone, Debug)]
pub struct OTError {
    pub code: OTErrorCode,
    pub msg: String,
}

impl OTError {
    pub fn new(code: OTErrorCode, msg: &str) -> OTError {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }
}

impl fmt::Display for OTError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "incompatible lengths") }
}

impl Error for OTError {
    fn source(&self) -> Option<&(dyn Error + 'static)> { None }
}

impl std::convert::From<serde_json::Error> for OTError {
    fn from(error: serde_json::Error) -> Self {
        ErrorBuilder::new(OTErrorCode::SerdeError)
            .error(error)
            .build()
    }
}

#[derive(Debug, Clone)]
pub enum OTErrorCode {
    IncompatibleLength,
    ApplyInsertFail,
    ApplyDeleteFail,
    ApplyFormatFail,
    ComposeOperationFail,
    IntervalOutOfBound,
    UndoFail,
    RedoFail,
    SerdeError,
}

pub struct ErrorBuilder {
    pub code: OTErrorCode,
    pub msg: Option<String>,
}

impl ErrorBuilder {
    pub fn new(code: OTErrorCode) -> Self { ErrorBuilder { code, msg: None } }

    pub fn msg<T>(mut self, msg: T) -> Self
    where
        T: Into<String>,
    {
        self.msg = Some(msg.into());
        self
    }

    pub fn error<T>(mut self, msg: T) -> Self
    where
        T: std::fmt::Debug,
    {
        self.msg = Some(format!("{:?}", msg));
        self
    }

    pub fn build(mut self) -> OTError {
        OTError::new(self.code, &self.msg.take().unwrap_or("".to_owned()))
    }
}
