use flowy_dispatch::prelude::{FromBytes, ToBytes};
use flowy_user::entities::UserDetail;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

use crate::{
    helper::{create_default_workspace_if_need, valid_email},
    tester::{TesterContext, TesterTrait},
};
use flowy_user::errors::UserError;
use flowy_workspace::errors::WorkspaceError;
use std::marker::PhantomData;

pub type UserTestBuilder = TestBuilder<FixedUserTester<WorkspaceError>>;
impl UserTestBuilder {
    pub fn new() -> Self {
        let mut builder = TestBuilder::test(Box::new(FixedUserTester::<WorkspaceError>::new()));
        builder.setup_default_workspace();
        builder
    }

    pub fn setup_default_workspace(&mut self) {
        self.login_if_need();
        let user_id = self.user_detail.as_ref().unwrap().id.clone();
        let _ = create_default_workspace_if_need(&user_id);
    }
}
pub type RandomUserTestBuilder = TestBuilder<RandomUserTester<UserError>>;
impl RandomUserTestBuilder {
    pub fn new() -> Self { TestBuilder::test(Box::new(RandomUserTester::<UserError>::new())) }

    pub fn reset(self) -> Self { self.login() }
}

pub struct TestBuilder<T: TesterTrait> {
    pub tester: Box<T>,
    pub user_detail: Option<UserDetail>,
}

impl<T> TestBuilder<T>
where
    T: TesterTrait,
{
    fn test(tester: Box<T>) -> Self {
        Self {
            tester,
            user_detail: None,
        }
    }

    pub fn login(mut self) -> Self {
        let user_detail = self.tester.login();
        self.user_detail = Some(user_detail);
        self
    }

    fn login_if_need(&mut self) {
        let user_detail = self.tester.login_if_need();
        self.user_detail = Some(user_detail);
    }

    pub fn logout(self) -> Self {
        // self.tester.logout();
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

    fn mut_context(&mut self) -> &mut TesterContext { &mut self.context }

    fn context(&self) -> &TesterContext { &self.context }
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
            context: TesterContext::new(valid_email()),
            err_phantom: PhantomData,
        }
    }
}

impl<Error> TesterTrait for FixedUserTester<Error>
where
    Error: FromBytes + Debug,
{
    type Error = Error;

    fn mut_context(&mut self) -> &mut TesterContext { &mut self.context }

    fn context(&self) -> &TesterContext { &self.context }
}
