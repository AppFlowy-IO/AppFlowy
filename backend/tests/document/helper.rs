// use crate::helper::*;
use crate::helper::{spawn_server, TestServer};
use flowy_document::{
    entities::doc::{DocDelta, QueryDocParams},
    module::FlowyDocument,
    services::doc::edit_doc_context::EditDocContext,
};

use flowy_net::config::ServerConfig;
use flowy_ot::core::Delta;

use flowy_test::{workspace::ViewTest, FlowyTest, FlowyTestSDK};
use flowy_user::services::user::UserSession;

use std::{str::FromStr, sync::Arc};
use tokio::time::{interval, Duration};

pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowyTest,
    flowy_document: Arc<FlowyDocument>,
    user_session: Arc<UserSession>,
    edit_context: Arc<EditDocContext>,
}

#[derive(Clone)]
pub enum DocScript {
    SendText(&'static str),
    SendBinary(Vec<u8>),
}

impl DocumentTest {
    pub async fn new() -> Self {
        let server = spawn_server().await;
        let server_config = ServerConfig::new(&server.host, "http", "ws");
        let flowy_test = FlowyTest::setup_with(server_config);

        init_user(&flowy_test).await;

        let edit_context = create_doc(&flowy_test).await;
        let user_session = flowy_test.sdk.user_session.clone();
        let flowy_document = flowy_test.sdk.flowy_document.clone();
        Self {
            server,
            flowy_test,
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

        let mut interval = interval(Duration::from_secs(5));
        interval.tick().await;
        interval.tick().await;
    }
}

async fn create_doc(flowy_test: &FlowyTest) -> Arc<EditDocContext> {
    let view_test = ViewTest::new(flowy_test).await;
    let doc_id = view_test.view.id.clone();
    let user_session = flowy_test.sdk.user_session.clone();
    let flowy_document = flowy_test.sdk.flowy_document.clone();

    let edit_context = flowy_document
        .open(QueryDocParams { doc_id }, user_session.db_pool().unwrap())
        .await
        .unwrap();

    edit_context
}

async fn init_user(flowy_test: &FlowyTest) {
    let _ = flowy_test.sign_up().await;

    let user_session = flowy_test.sdk.user_session.clone();
    user_session.init_user().await.unwrap();
}
