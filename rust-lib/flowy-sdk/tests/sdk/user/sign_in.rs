use crate::helper::*;
use flowy_sys::prelude::*;
use flowy_user::prelude::*;
use std::convert::{TryFrom, TryInto};

#[test]
fn sign_in_without_password() {
    let params = UserSignInParams {
        email: "annie@appflowy.io".to_string(),
        password: "".to_string(),
    };
    let bytes: Vec<u8> = params.try_into().unwrap();
    let resp = EventTester::new(SignIn, Payload::Bytes(bytes)).sync_send();
    match resp.payload {
        Payload::None => {},
        Payload::Bytes(bytes) => {
            let result = UserSignInResult::try_from(&bytes).unwrap();
            dbg!(&result);
        },
    }

    assert_eq!(resp.status_code, StatusCode::Ok);
}
