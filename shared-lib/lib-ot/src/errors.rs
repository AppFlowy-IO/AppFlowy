use std::{error::Error, fmt, fmt::Debug, str::Utf8Error};

#[derive(Clone, Debug)]
pub struct OTError {
    pub code: OTErrorCode,
    pub msg: String,
}

macro_rules! static_ot_error {
    ($name:ident, $code:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> OTError { $code.into() }
    };
}

impl std::convert::From<OTErrorCode> for OTError {
    fn from(code: OTErrorCode) -> Self {
        OTError {
            code: code.clone(),
            msg: format!("{:?}", code),
        }
    }
}

impl OTError {
    pub fn new(code: OTErrorCode, msg: &str) -> OTError {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_ot_error!(duplicate_revision, OTErrorCode::DuplicatedRevision);
}

impl fmt::Display for OTError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "incompatible lengths") }
}

impl Error for OTError {
    fn source(&self) -> Option<&(dyn Error + 'static)> { None }
}

impl std::convert::From<serde_json::Error> for OTError {
    fn from(error: serde_json::Error) -> Self { ErrorBuilder::new(OTErrorCode::SerdeError).error(error).build() }
}

impl std::convert::From<Utf8Error> for OTError {
    fn from(error: Utf8Error) -> Self { ErrorBuilder::new(OTErrorCode::SerdeError).error(error).build() }
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
    DuplicatedRevision,
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

    pub fn build(mut self) -> OTError { OTError::new(self.code, &self.msg.take().unwrap_or_else(|| "".to_owned())) }
}
