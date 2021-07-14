use flowy_dispatch::prelude::*;
pub use flowy_sdk::*;
use flowy_user::{
    errors::UserError,
    event::UserEvent::{SignIn, SignOut},
    prelude::*,
};
use std::{
    convert::TryFrom,
    fmt::{Debug, Display},
    fs,
    hash::Hash,
    marker::PhantomData,
    path::PathBuf,
    sync::Once,
    thread,
};

pub mod prelude {
    pub use crate::Tester;
    pub use flowy_dispatch::prelude::*;
    pub use std::convert::TryFrom;
}

static INIT: Once = Once::new();
pub fn init_sdk() {
    let root_dir = root_dir();

    INIT.call_once(|| {
        FlowySDK::new(&root_dir).construct();
    });
}

fn root_dir() -> String {
    // https://doc.rust-lang.org/cargo/reference/environment-variables.html
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or("./".to_owned());
    let mut path_buf = fs::canonicalize(&PathBuf::from(&manifest_dir)).unwrap();
    path_buf.pop(); // rust-lib
    path_buf.push("flowy-test");
    path_buf.push("temp");
    path_buf.push("flowy");

    let root_dir = path_buf.to_str().unwrap().to_string();
    if !std::path::Path::new(&root_dir).exists() {
        std::fs::create_dir_all(&root_dir).unwrap();
    }
    root_dir
}

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
        let mut inner = self.inner.unwrap();
        self.inner = Some(inner.request(request));
        self
    }

    pub fn sync_send(mut self) -> Self {
        let inner = self.inner.take().unwrap();
        self.inner = Some(inner.sync_send());
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
}

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

    pub fn request<P>(mut self, request: P) -> Self
    where
        P: ToBytes,
    {
        let mut inner_request = self.inner_request.take().unwrap();
        let bytes = request.into_bytes().unwrap();
        inner_request = inner_request.payload(bytes);
        self.inner_request = Some(inner_request);
        self
    }

    pub fn assert_status_code(mut self, status_code: StatusCode) -> Self {
        self.assert_status_code = Some(status_code);
        self
    }

    pub fn assert_error(mut self) -> Self {
        self.assert_status_code = Some(StatusCode::Err);
        self
    }

    pub async fn async_send(mut self) -> Self {
        let resp =
            EventDispatch::async_send(self.inner_request.take().unwrap(), |_| Box::pin(async {}))
                .await;

        check(&resp, &self.assert_status_code);
        self.response = Some(resp);
        self
    }

    pub fn sync_send(mut self) -> Self {
        let resp = EventDispatch::sync_send(self.inner_request.take().unwrap());
        check(&resp, &self.assert_status_code);
        self.response = Some(resp);
        self
    }

    pub fn parse<R>(self) -> R
    where
        R: FromBytes,
    {
        let response = self.response.unwrap();
        if response.status_code == StatusCode::Err {
            let error = <Data<Error>>::try_from(response.payload)
                .unwrap()
                .into_inner();
            dbg!(&error);
            panic!("")
        } else {
            <Data<R>>::try_from(response.payload).unwrap().into_inner()
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

fn check(response: &EventResponse, status_code: &Option<StatusCode>) {
    if let Some(ref status_code) = status_code {
        if &response.status_code != status_code {
            eprintln!("{:#?}", response);
        }
        assert_eq!(&response.status_code, status_code)
    }
}

fn new_user_after_login() -> UserDetail {
    init_sdk();
    let _ = EventDispatch::sync_send(ModuleRequest::new(SignOut));
    let request = SignInRequest {
        email: valid_email(),
        password: valid_password(),
    };

    let user_detail = Tester::<UserError>::new(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();

    user_detail
}

pub(crate) fn valid_email() -> String { "annie@appflowy.io".to_string() }

pub(crate) fn valid_password() -> String { "HelloWorld!123".to_string() }
