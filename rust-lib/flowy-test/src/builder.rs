use flowy_dispatch::prelude::{FromBytes, ToBytes};
use flowy_user::entities::UserDetail;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

use crate::{
    helper::{create_default_workspace_if_need, login_email, login_password},
    init_test_sdk,
    tester::{TesterContext, TesterTrait},
};
use flowy_document::errors::DocError;
use flowy_user::errors::UserError;
use flowy_workspace::errors::WorkspaceError;
use std::marker::PhantomData;

pub type WorkspaceTestBuilder = Builder<RandomUserTester<WorkspaceError>>;
impl WorkspaceTestBuilder {
    pub fn new() -> Self { Builder::test(Box::new(RandomUserTester::<WorkspaceError>::new())) }
}

pub type DocTestBuilder = Builder<RandomUserTester<DocError>>;
impl DocTestBuilder {
    pub fn new() -> Self { Builder::test(Box::new(RandomUserTester::<DocError>::new())) }
}

pub type UserTestBuilder = Builder<RandomUserTester<UserError>>;
impl UserTestBuilder {
    pub fn new() -> Self { Builder::test(Box::new(RandomUserTester::<UserError>::new())) }

    pub fn sign_up(mut self) -> SignUpContext {
        let (user_detail, password) = self.tester.sign_up();
        let _ = create_default_workspace_if_need(&user_detail.id);
        SignUpContext { user_detail, password }
    }

    pub fn sign_in(mut self) -> Self {
        let user_detail = self.tester.sign_in();
        self.user_detail = Some(user_detail);
        self
    }

    fn login_if_need(&mut self) {
        let user_detail = self.tester.login_if_need();
        self.user_detail = Some(user_detail);
    }

    pub fn get_user_detail(&self) -> &Option<UserDetail> { &self.user_detail }
}

pub struct Builder<T: TesterTrait> {
    pub tester: Box<T>,
    user_detail: Option<UserDetail>,
}

impl<T> Builder<T>
where
    T: TesterTrait,
{
    fn test(tester: Box<T>) -> Self {
        init_test_sdk();
        Self { tester, user_detail: None }
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

pub struct SignUpContext {
    pub user_detail: UserDetail,
    pub password: String,
}
