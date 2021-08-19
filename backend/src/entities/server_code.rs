use serde_repr::*;

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug)]
#[repr(u16)]
pub enum ServerCode {
    Success          = 0,
    InvalidToken     = 1,
    InternalError    = 2,
    Unauthorized     = 3,
    PayloadOverflow  = 4,
    PayloadSerdeFail = 5,
}
