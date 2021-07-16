use crate::init_sdk;
use flowy_dispatch::prelude::*;
pub use flowy_sdk::*;
use flowy_user::prelude::*;
use std::{
    convert::TryFrom,
    fmt::{Debug, Display},
    hash::Hash,
    marker::PhantomData,
    thread,
};

pub struct Tester<Error> {
    inner_request: Option<ModuleRequest>,
    assert_status_code: Option<StatusCode>,
    response: Option<EventResponse>,
    err_phantom: PhantomData<Error>,
    user_detail: Option<UserDetail>,
}

impl<Error> Tester<Error>
where
    Error: FromBytes + Debug,
{
    pub fn new<E>(event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        init_sdk();
        log::trace!(
            "{:?} thread started: thread_id= {}",
            thread::current(),
            thread_id::get()
        );

        Self {
            inner_request: Some(ModuleRequest::new(event)),
            assert_status_code: None,
            response: None,
            err_phantom: PhantomData,
            user_detail: None,
        }
    }

    pub fn set_request<P>(&mut self, request: P)
    where
        P: ToBytes,
    {
        let mut inner_request = self.inner_request.take().unwrap();
        let bytes = request.into_bytes().unwrap();
        inner_request = inner_request.payload(bytes);
        self.inner_request = Some(inner_request);
    }

    pub fn assert_error(&mut self) { self.assert_status_code = Some(StatusCode::Err); }

    pub fn assert_success(&mut self) { self.assert_status_code = Some(StatusCode::Ok); }

    pub async fn async_send(&mut self) {
        assert_eq!(self.inner_request.is_some(), true, "must set event");

        let resp = EventDispatch::async_send(self.inner_request.take().unwrap()).await;
        self.response = Some(resp);
    }

    pub fn sync_send(&mut self) {
        let resp = EventDispatch::sync_send(self.inner_request.take().unwrap());
        self.response = Some(resp);
    }

    pub fn parse<R>(self) -> R
    where
        R: FromBytes,
    {
        let response = self.response.unwrap();
        match response.parse::<R, Error>() {
            Ok(Ok(data)) => data,
            Ok(Err(e)) => panic!("parse failed: {:?}", e),
            Err(e) => panic!("Internal error: {:?}", e),
        }
    }

    pub fn error(self) -> Error {
        let response = self.response.unwrap();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<Error>>::try_from(response.payload)
            .unwrap()
            .into_inner()
    }
}

pub struct RandomUserTester<Error> {
    context: TesterContext,
    err_phantom: PhantomData<Error>,
}

impl<Error> RandomUserTester<Error>
where
    Error: FromBytes + Debug,
{
    pub fn new() -> Self {
        Self {
            context: TesterContext::default(),
            err_phantom: PhantomData,
        }
    }
}

impl<Error> TesterTrait for RandomUserTester<Error>
where
    Error: FromBytes + Debug,
{
    type Error = Error;

    fn context(&mut self) -> &mut TesterContext { &mut self.context }
}

pub struct TesterContext {
    request: Option<ModuleRequest>,
    status_code: StatusCode,
    response: Option<EventResponse>,
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

    fn context(&mut self) -> &mut TesterContext;

    fn assert_error(&mut self) { self.context().status_code = StatusCode::Err; }

    fn assert_success(&mut self) { self.context().status_code = StatusCode::Ok; }

    fn set_payload<P>(&mut self, payload: P)
    where
        P: ToBytes,
    {
        let bytes = payload.into_bytes().unwrap();
        let mut module_request = self.context().request.take().unwrap();
        self.context().request = Some(module_request.payload(bytes));
    }

    fn sync_send(&mut self) {
        let resp = EventDispatch::sync_send(self.context().request.take().unwrap());
        self.context().response = Some(resp);
    }

    fn parse<R>(&mut self) -> R
    where
        R: FromBytes,
    {
        let response = self.context().response.clone().unwrap();
        match response.parse::<R, Self::Error>() {
            Ok(Ok(data)) => data,
            Ok(Err(e)) => panic!("parse failed: {:?}", e),
            Err(e) => panic!("Internal error: {:?}", e),
        }
    }

    fn error(&mut self) -> Self::Error {
        let response = self.context().response.clone().unwrap();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<Self::Error>>::try_from(response.payload)
            .unwrap()
            .into_inner()
    }
}
