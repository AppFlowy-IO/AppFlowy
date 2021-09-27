use crate::helper::*;
use flowy_document::{
    entities::doc::{CreateDocParams, DocDelta, QueryDocParams},
    module::FlowyDocument,
    services::doc::edit_doc_context::EditDocContext,
};
use flowy_infra::uuid;
use flowy_ot::core::Delta;
use flowy_sdk::{FlowySDK, FlowySDKConfig};
use flowy_test::{prelude::root_dir, FlowyTestSDK};
use flowy_user::{entities::SignUpParams, services::user::UserSession};
use flowy_workspace::prelude::DOC_DEFAULT_DATA;
use std::{str::FromStr, sync::Arc};

pub struct DocumentTest {
    server: TestServer,
    sdk: FlowyTestSDK,
    flowy_document: Arc<FlowyDocument>,
    user_session: Arc<UserSession>,
    edit_context: Arc<EditDocContext>,
}

#[derive(Clone)]
pub enum DocScript {
    SendText(&'static str),
    SendBinary(Vec<u8>),
}

async fn create_doc(user_session: Arc<UserSession>, flowy_document: Arc<FlowyDocument>) -> Arc<EditDocContext> {
    let conn = user_session.db_pool().unwrap().get().unwrap();
    let doc_id = uuid();
    let params = CreateDocParams {
        id: doc_id.clone(),
        data: DOC_DEFAULT_DATA.to_string(),
    };
    let _ = flowy_document.create(params, &*conn).unwrap();

    let edit_context = flowy_document
        .open(QueryDocParams { doc_id }, user_session.db_pool().unwrap())
        .await
        .unwrap();

    edit_context
}

async fn init_user(user_session: Arc<UserSession>) {
    let params = SignUpParams {
        email: format!("{}@gmail.com", uuid()),
        name: "nathan".to_string(),
        password: "HelloWorld!@12".to_string(),
    };

    user_session.sign_up(params).await.unwrap();
    user_session.init_user().await.unwrap();
}

impl DocumentTest {
    pub async fn new() -> Self {
        let server = spawn_server().await;
        let config = FlowySDKConfig::new(&root_dir(), &server.host, "http", "ws").log_filter("debug");
        let sdk = FlowySDK::new(config);

        let flowy_document = sdk.flowy_document.clone();
        let user_session = sdk.user_session.clone();

        init_user(user_session.clone()).await;

        let edit_context = create_doc(user_session.clone(), flowy_document.clone()).await;

        Self {
            server,
            sdk,
            flowy_document,
            user_session,
            edit_context,
        }
    }

    pub async fn run_scripts(self, scripts: Vec<DocScript>) {
        for script in scripts {
            match script {
                DocScript::SendText(s) => {
                    let delta = Delta::from_str(s).unwrap();
                    let data = delta.to_json();
                    let doc_delta = DocDelta {
                        doc_id: self.edit_context.doc_id.clone(),
                        data,
                    };

                    self.flowy_document.apply_doc_delta(doc_delta).await;
                },
                DocScript::SendBinary(_bytes) => {},
            }
        }
        std::mem::forget(self);
    }
}
