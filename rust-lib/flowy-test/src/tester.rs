use crate::{
    helper::{login_password, random_email},
    init_test_sdk,
};
use flowy_dispatch::prelude::*;
pub use flowy_sdk::*;
use flowy_user::{
    errors::UserError,
    event::UserEvent::{GetUserProfile, SignOut, SignUp},
    prelude::*,
};

use crate::helper::login_email;
use flowy_user::event::UserEvent::SignIn;
use std::{
    convert::TryFrom,
    fmt::{Debug, Display},
    hash::Hash,
};

#[allow(dead_code)]
pub struct TesterContext {
    request: Option<ModuleRequest>,
    response: Option<EventResponse>,
    status_code: StatusCode,
}

impl TesterContext {
    pub fn new(email: String) -> Self { TesterContext::default() }
}

impl std::default::Default for TesterContext {
    fn default() -> Self {
        Self {
            request: None,
            status_code: StatusCode::Ok,
            response: None,
        }
    }
}

pub trait TesterTrait {
    type Error: FromBytes + Debug;

    fn mut_context(&mut self) -> &mut TesterContext;

    fn context(&self) -> &TesterContext;

    fn assert_error(&mut self) { self.mut_context().status_code = StatusCode::Err; }

    fn assert_success(&mut self) { self.mut_context().status_code = StatusCode::Ok; }

    fn set_event<E>(&mut self, event: E)
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        self.mut_context().request = Some(ModuleRequest::new(event));
    }

    fn set_payload<P>(&mut self, payload: P)
    where
        P: ToBytes,
    {
        match payload.into_bytes() {
            Ok(bytes) => {
                let module_request = self.mut_context().request.take().unwrap();
                self.mut_context().request = Some(module_request.payload(bytes));
            },
            Err(e) => {
                log::error!("Set payload failed: {:?}", e);
            },
        }
    }

    fn sync_send(&mut self) {
        let resp = EventDispatch::sync_send(self.mut_context().request.take().unwrap());
        self.mut_context().response = Some(resp);
    }

    // TODO: support return Option<R>
    fn parse<R>(&mut self) -> R
    where
        R: FromBytes,
    {
        let response = self.mut_context().response.clone().unwrap();
        match response.parse::<R, Self::Error>() {
            Ok(Ok(data)) => data,
            Ok(Err(e)) => {
                panic!("parse failed: {:?}", e)
            },
            Err(e) => panic!("Internal error: {:?}", e),
        }
    }

    fn error(&mut self) -> Self::Error {
        let response = self.mut_context().response.clone().unwrap();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<Self::Error>>::try_from(response.payload).unwrap().into_inner()
    }

    fn sign_up(&self) -> (UserDetail, String) {
        let password = login_password();
        let payload = SignUpRequest {
            email: random_email(),
            name: "app flowy".to_string(),
            password: password.clone(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(SignUp).payload(payload);
        let user_detail = EventDispatch::sync_send(request).parse::<UserDetail, UserError>().unwrap().unwrap();

        (user_detail, password)
    }

    fn sign_in(&self) -> UserDetail {
        let payload = SignInRequest {
            email: login_email(),
            password: login_password(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(SignIn).payload(payload);
        let user_detail = EventDispatch::sync_send(request).parse::<UserDetail, UserError>().unwrap().unwrap();

        user_detail
    }

    fn login_if_need(&self) -> UserDetail {
        match EventDispatch::sync_send(ModuleRequest::new(GetUserProfile))
            .parse::<UserDetail, UserError>()
            .unwrap()
        {
            Ok(user_detail) => user_detail,
            Err(_e) => self.sign_in(),
        }
    }

    fn logout(&self) { let _ = EventDispatch::sync_send(ModuleRequest::new(SignOut)); }
}
