use crate::{
    helper::{random_valid_email, valid_password},
    init_test_sdk,
};
use flowy_dispatch::prelude::*;
pub use flowy_sdk::*;
use flowy_user::{
    errors::UserError,
    event::UserEvent::{GetStatus, SignIn, SignOut},
    prelude::*,
};
use std::{
    convert::TryFrom,
    fmt::{Debug, Display},
    hash::Hash,
    sync::Arc,
};

pub struct TesterContext {
    request: Option<ModuleRequest>,
    response: Option<EventResponse>,
    status_code: StatusCode,
    server: ArcFlowyServer,
    user_email: String,
}

impl TesterContext {
    pub fn new(email: String) -> Self {
        let mut ctx = TesterContext::default();
        ctx.user_email = email;
        ctx
    }
}

impl std::default::Default for TesterContext {
    fn default() -> Self {
        Self {
            request: None,
            status_code: StatusCode::Ok,
            response: None,
            server: Arc::new(FlowyServerMocker {}),
            user_email: random_valid_email(),
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
        init_test_sdk(self.context().server.clone());
        self.mut_context().request = Some(ModuleRequest::new(event));
    }

    fn set_payload<P>(&mut self, payload: P)
    where
        P: ToBytes,
    {
        let bytes = payload.into_bytes().unwrap();
        let module_request = self.mut_context().request.take().unwrap();
        self.mut_context().request = Some(module_request.payload(bytes));
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
            Ok(Err(e)) => panic!("parse failed: {:?}", e),
            Err(e) => panic!("Internal error: {:?}", e),
        }
    }

    fn error(&mut self) -> Self::Error {
        let response = self.mut_context().response.clone().unwrap();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<Self::Error>>::try_from(response.payload)
            .unwrap()
            .into_inner()
    }

    fn login(&self) -> UserDetail {
        init_test_sdk(self.context().server.clone());
        let payload = SignInRequest {
            email: self.context().user_email.clone(),
            password: valid_password(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(SignIn).payload(payload);
        let user_detail = EventDispatch::sync_send(request)
            .parse::<UserDetail, UserError>()
            .unwrap()
            .unwrap();

        user_detail
    }

    fn login_if_need(&self) -> UserDetail {
        init_test_sdk(self.context().server.clone());
        match EventDispatch::sync_send(ModuleRequest::new(GetStatus))
            .parse::<UserDetail, UserError>()
            .unwrap()
        {
            Ok(user_detail) => user_detail,
            Err(_e) => self.login(),
        }
    }

    fn logout(&self) {
        init_test_sdk(self.context().server.clone());
        let _ = EventDispatch::sync_send(ModuleRequest::new(SignOut));
    }
}
