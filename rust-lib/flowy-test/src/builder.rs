use flowy_dispatch::prelude::{FromBytes, ToBytes};
use flowy_user::entities::UserDetail;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

use crate::tester::{TesterContext, TesterTrait};
use flowy_user::errors::UserError;
use flowy_workspace::errors::WorkspaceError;
use std::marker::PhantomData;

pub type WorkspaceTestBuilder = TestBuilder<FixedUserTester<WorkspaceError>>;
impl WorkspaceTestBuilder {
    pub fn new() -> Self {
        Self {
            tester: Box::new(FixedUserTester::<WorkspaceError>::new()),
            user_detail: None,
        }
    }
}

pub type UserTestBuilder = TestBuilder<RandomUserTester<UserError>>;
impl UserTestBuilder {
    pub fn new() -> Self {
        Self {
            tester: Box::new(RandomUserTester::<UserError>::new()),
            user_detail: None,
        }
    }
}

pub struct TestBuilder<T: TesterTrait> {
    pub tester: Box<T>,
    pub user_detail: Option<UserDetail>,
}

impl<T> TestBuilder<T>
where
    T: TesterTrait,
{
    pub fn login(mut self) -> Self {
        let user_detail = self.tester.login();
        self.user_detail = Some(user_detail);
        self
    }

    pub fn logout(self) -> Self {
        self.tester.logout();
        self
    }

    pub fn request<P>(mut self, request: P) -> Self
    where
        P: ToBytes,
    {
        self.tester.set_payload(request);
        self
    }

    pub fn event<E>(mut self, event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        self.tester.set_event(event);
        self
    }

    pub fn sync_send(mut self) -> Self {
        self.tester.sync_send();
        self
    }

    pub fn parse<R>(mut self) -> R
    where
        R: FromBytes,
    {
        self.tester.parse::<R>()
    }

    pub fn error(mut self) -> <T as TesterTrait>::Error { self.tester.error() }

    pub fn assert_error(mut self) -> Self {
        self.tester.assert_error();
        self
    }

    pub fn assert_success(mut self) -> Self {
        self.tester.assert_success();
        self
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

pub struct FixedUserTester<Error> {
    context: TesterContext,
    err_phantom: PhantomData<Error>,
}

impl<Error> FixedUserTester<Error>
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

impl<Error> TesterTrait for FixedUserTester<Error>
where
    Error: FromBytes + Debug,
{
    type Error = Error;

    fn context(&mut self) -> &mut TesterContext { &mut self.context }
}
