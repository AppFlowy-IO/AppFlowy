use flowy_dispatch::prelude::{EventDispatch, EventResponse, FromBytes, ModuleRequest, StatusCode, ToBytes};
use flowy_user::entities::UserDetail;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

use crate::helper::{create_default_workspace_if_need, login_email, login_password, random_email};
use flowy_dispatch::prelude::*;
use flowy_document::errors::DocError;
pub use flowy_sdk::*;
use flowy_user::{
    errors::UserError,
    event::UserEvent::{SignOut, SignUp},
    prelude::*,
};
use flowy_workspace::errors::WorkspaceError;
use std::{marker::PhantomData, sync::Arc};

use crate::FlowyTestSDK;
use flowy_user::event::UserEvent::SignIn;
use std::convert::TryFrom;

pub type DocTestBuilder = Builder<DocError>;
impl DocTestBuilder {
    pub fn new(sdk: FlowyTestSDK) -> Self { Builder::test(TestContext::new(sdk)) }
}

pub type WorkspaceTestBuilder = Builder<WorkspaceError>;
impl WorkspaceTestBuilder {
    pub fn new(sdk: FlowyTestSDK) -> Self { Builder::test(TestContext::new(sdk)) }
}

pub type UserTestBuilder = Builder<UserError>;
impl UserTestBuilder {
    pub fn new(sdk: FlowyTestSDK) -> Self { Builder::test(TestContext::new(sdk)) }

    pub fn sign_up(self) -> SignUpContext {
        let password = login_password();
        let payload = SignUpRequest {
            email: random_email(),
            name: "app flowy".to_string(),
            password: password.clone(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(SignUp).payload(payload);
        let user_detail = EventDispatch::sync_send(self.dispatch(), request)
            .parse::<UserDetail, UserError>()
            .unwrap()
            .unwrap();

        let _ = create_default_workspace_if_need(self.dispatch(), &user_detail.id);
        SignUpContext { user_detail, password }
    }

    #[allow(dead_code)]
    fn sign_in(mut self) -> Self {
        let payload = SignInRequest {
            email: login_email(),
            password: login_password(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(SignIn).payload(payload);
        let user_detail = EventDispatch::sync_send(self.dispatch(), request)
            .parse::<UserDetail, UserError>()
            .unwrap()
            .unwrap();

        self.user_detail = Some(user_detail);
        self
    }

    #[allow(dead_code)]
    fn logout(&self) { let _ = EventDispatch::sync_send(self.dispatch(), ModuleRequest::new(SignOut)); }

    pub fn user_detail(&self) -> &Option<UserDetail> { &self.user_detail }
}

#[derive(Clone)]
pub struct Builder<E> {
    context: TestContext,
    user_detail: Option<UserDetail>,
    err_phantom: PhantomData<E>,
}

impl<E> Builder<E>
where
    E: FromBytes + Debug,
{
    pub(crate) fn test(context: TestContext) -> Self {
        Self {
            context,
            user_detail: None,
            err_phantom: PhantomData,
        }
    }

    pub fn request<P>(mut self, payload: P) -> Self
    where
        P: ToBytes,
    {
        match payload.into_bytes() {
            Ok(bytes) => {
                let module_request = self.get_request();
                self.context.request = Some(module_request.payload(bytes))
            },
            Err(e) => {
                log::error!("Set payload failed: {:?}", e);
            },
        }
        self
    }

    pub fn event<Event>(mut self, event: Event) -> Self
    where
        Event: Eq + Hash + Debug + Clone + Display,
    {
        self.context.request = Some(ModuleRequest::new(event));
        self
    }

    pub fn sync_send(mut self) -> Self {
        let request = self.get_request();
        let resp = EventDispatch::sync_send(self.dispatch(), request);
        self.context.response = Some(resp);
        self
    }

    pub fn parse<R>(self) -> R
    where
        R: FromBytes,
    {
        let response = self.get_response();
        match response.parse::<R, E>() {
            Ok(Ok(data)) => data,
            Ok(Err(e)) => {
                panic!("parse failed: {:?}", e)
            },
            Err(e) => panic!("Internal error: {:?}", e),
        }
    }

    pub fn error(self) -> E {
        let response = self.get_response();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<E>>::try_from(response.payload).unwrap().into_inner()
    }

    pub fn assert_error(self) -> Self {
        // self.context.assert_error();
        self
    }

    pub fn assert_success(self) -> Self {
        // self.context.assert_success();
        self
    }

    pub fn sdk(&self) -> FlowySDK { self.context.sdk.clone() }

    fn dispatch(&self) -> Arc<EventDispatch> { self.context.sdk.dispatch() }

    fn get_response(&self) -> EventResponse { self.context.response.as_ref().expect("must call sync_send first").clone() }

    fn get_request(&mut self) -> ModuleRequest { self.context.request.take().expect("must call event first") }
}

#[derive(Clone)]
pub struct TestContext {
    sdk: FlowyTestSDK,
    request: Option<ModuleRequest>,
    response: Option<EventResponse>,
}

impl TestContext {
    pub fn new(sdk: FlowyTestSDK) -> Self {
        Self {
            sdk,
            request: None,
            response: None,
        }
    }
}
pub struct SignUpContext {
    pub user_detail: UserDetail,
    pub password: String,
}
