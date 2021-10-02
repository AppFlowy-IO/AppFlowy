use std::sync::Arc;

use actix_web::web::Data;
use futures_util::{stream, stream::StreamExt};
use sqlx::PgPool;
use tokio::time::{sleep, Duration};

use backend::service::doc::doc::DocManager;
use flowy_document::{entities::doc::QueryDocParams, services::doc::edit::ClientEditDoc as ClientEditDocContext};
use flowy_net::config::ServerConfig;
use flowy_test::{workspace::ViewTest, FlowyTest};
use flowy_user::services::user::UserSession;

// use crate::helper::*;
use crate::helper::{spawn_server, TestServer};

pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowyTest,
}
#[derive(Clone)]
pub enum DocScript {
    ConnectWs,
    SendText(usize, &'static str),
    AssertClient(&'static str),
    AssertServer(&'static str),
}

impl DocumentTest {
    pub async fn new() -> Self {
        let server = spawn_server().await;
        let server_config = ServerConfig::new(&server.host, "http", "ws");
        let flowy_test = FlowyTest::setup_with(server_config);
        Self { server, flowy_test }
    }

    pub async fn run_scripts(self, scripts: Vec<DocScript>) {
        let _ = self.flowy_test.sign_up().await;
        let DocumentTest { server, flowy_test } = self;
        let script_context = ScriptContext {
            client_edit_context: create_doc(&flowy_test).await,
            user_session: flowy_test.sdk.user_session.clone(),
            doc_manager: server.app_ctx.doc_biz.manager.clone(),
            pool: Data::new(server.pg_pool.clone()),
        };

        run_scripts(script_context, scripts).await;
        std::mem::forget(flowy_test);
        sleep(Duration::from_secs(5)).await;
    }
}

#[derive(Clone)]
struct ScriptContext {
    client_edit_context: Arc<ClientEditDocContext>,
    user_session: Arc<UserSession>,
    doc_manager: Arc<DocManager>,
    pool: Data<PgPool>,
}

async fn run_scripts(context: ScriptContext, scripts: Vec<DocScript>) {
    let mut fut_scripts = vec![];
    for script in scripts {
        let context = context.clone();
        let fut = async move {
            match script {
                DocScript::ConnectWs => {
                    let token = context.user_session.token().unwrap();
                    let _ = context.user_session.start_ws_connection(&token).await.unwrap();
                },
                DocScript::SendText(index, s) => {
                    context.client_edit_context.insert(index, s).await.unwrap();
                },
                DocScript::AssertClient(s) => {
                    let json = context.client_edit_context.doc_json().await.unwrap();
                    assert_eq(s, &json);
                },
                DocScript::AssertServer(s) => {
                    let edit_doc = context
                        .doc_manager
                        .get(&context.client_edit_context.doc_id, context.pool)
                        .await
                        .unwrap()
                        .unwrap();
                    let json = edit_doc.document_json().await.unwrap();
                    assert_eq(s, &json);
                },
            }
        };
        fut_scripts.push(fut);
    }

    let mut stream = stream::iter(fut_scripts);
    while let Some(script) = stream.next().await {
        let _ = script.await;
    }
}

fn assert_eq(expect: &str, receive: &str) {
    if expect != receive {
        log::error!("expect: {}", expect);
        log::error!("but receive: {}", receive);
    }
    assert_eq!(expect, receive);
}

async fn create_doc(flowy_test: &FlowyTest) -> Arc<ClientEditDocContext> {
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
