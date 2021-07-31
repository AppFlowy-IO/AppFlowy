use std::{error::Error, fmt};

#[derive(Clone, Debug)]
pub struct OTError;

impl fmt::Display for OTError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "incompatible lengths") }
}

impl Error for OTError {
    fn source(&self) -> Option<&(dyn Error + 'static)> { None }
}
