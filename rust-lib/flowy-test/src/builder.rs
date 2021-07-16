use crate::{helper::new_user_after_login, init_sdk, tester::Tester};
use flowy_dispatch::prelude::{EventDispatch, FromBytes, ModuleRequest, ToBytes};
use flowy_user::{entities::UserDetail, event::UserEvent::SignOut};
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

pub struct TestBuilder<Error> {
    login: Option<bool>,
    inner: Option<Tester<Error>>,
    pub user_detail: Option<UserDetail>,
}

impl<Error> TestBuilder<Error>
where
    Error: FromBytes + Debug,
{
    pub fn new() -> Self {
        TestBuilder::<Error> {
            login: None,
            inner: None,
            user_detail: None,
        }
    }

    pub fn login(mut self) -> Self {
        let user_detail = new_user_after_login();
        self.user_detail = Some(user_detail);
        self
    }

    pub fn logout(self) -> Self {
        init_sdk();
        let _ = EventDispatch::sync_send(ModuleRequest::new(SignOut));
        self
    }

    pub fn event<E>(mut self, event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        self.inner = Some(Tester::<Error>::new(event));
        self
    }

    pub fn request<P>(mut self, request: P) -> Self
    where
        P: ToBytes,
    {
        self.inner.as_mut().unwrap().set_request(request);
        self
    }

    pub fn sync_send(mut self) -> Self {
        self.inner.as_mut().unwrap().sync_send();
        self
    }

    pub fn parse<R>(mut self) -> R
    where
        R: FromBytes,
    {
        let inner = self.inner.take().unwrap();
        inner.parse::<R>()
    }

    pub fn error(mut self) -> Error {
        let inner = self.inner.take().unwrap();
        inner.error()
    }

    pub fn assert_error(mut self) -> Self {
        self.inner.as_mut().unwrap().assert_error();
        self
    }

    pub fn assert_success(mut self) -> Self {
        self.inner.as_mut().unwrap().assert_success();
        self
    }
}
