use flowy_dispatch::prelude::*;
pub use flowy_sdk::*;
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
    pub use crate::EventTester;
    pub use flowy_dispatch::prelude::*;
    pub use std::convert::TryFrom;
}

static INIT: Once = Once::new();
pub fn init_sdk() {
    let root_dir = root_dir();

    INIT.call_once(|| {
        FlowySDK::init_log(&root_dir);
        FlowySDK::init(&root_dir);
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

pub struct EventTester<ErrType> {
    inner_request: Option<ModuleRequest>,
    assert_status_code: Option<StatusCode>,
    response: Option<EventResponse>,
    phantom: PhantomData<ErrType>,
}

impl<ErrType> EventTester<ErrType>
where
    ErrType: FromBytes + Debug,
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
            phantom: PhantomData,
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

    #[allow(dead_code)]
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
            let error = <Data<ErrType>>::try_from(response.payload)
                .unwrap()
                .into_inner();
            dbg!(&error);
            panic!("")
        } else {
            <Data<R>>::try_from(response.payload).unwrap().into_inner()
        }
    }

    pub fn error(self) -> ErrType {
        let response = self.response.unwrap();
        assert_eq!(response.status_code, StatusCode::Err);
        <Data<ErrType>>::try_from(response.payload)
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
