use std::sync::Arc;

use actix_web::web::Data;
use futures_util::{stream, stream::StreamExt};
use sqlx::PgPool;
use tokio::time::{sleep, Duration};

use backend::service::doc::{crud::update_doc, doc::DocManager};
use flowy_document::{entities::doc::QueryDocParams, services::doc::edit::ClientEditDoc as ClientEditDocContext};
use flowy_net::config::ServerConfig;
use flowy_test::{workspace::ViewTest, FlowyTest};
use flowy_user::services::user::UserSession;

// use crate::helper::*;
use crate::helper::{spawn_server, TestServer};
use flowy_document::protobuf::UpdateDocParams;

use flowy_ot::core::{Attribute, Interval};
use parking_lot::RwLock;
use serde::__private::Formatter;

pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowyTest,
}
#[derive(Clone)]
pub enum DocScript {
    ConnectWs,
    InsertText(usize, &'static str),
    FormatText(Interval, Attribute),
    AssertClient(&'static str),
    AssertServer(&'static str, i64),
    SetServerDocument(String, i64), // delta_json, rev_id
    OpenDoc,
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
        let script_context = Arc::new(RwLock::new(ScriptContext::new(flowy_test, server).await));
        run_scripts(script_context, scripts).await;
        sleep(Duration::from_secs(5)).await;
    }
}

#[derive(Clone)]
struct ScriptContext {
    client_edit_context: Option<Arc<ClientEditDocContext>>,
    flowy_test: FlowyTest,
    user_session: Arc<UserSession>,
    doc_manager: Arc<DocManager>,
    pool: Data<PgPool>,
    doc_id: String,
}

impl ScriptContext {
    async fn new(flowy_test: FlowyTest, server: TestServer) -> Self {
        let user_session = flowy_test.sdk.user_session.clone();
        let doc_id = create_doc(&flowy_test).await;

        Self {
            client_edit_context: None,
            flowy_test,
            user_session,
            doc_manager: server.app_ctx.doc_biz.manager.clone(),
            pool: Data::new(server.pg_pool.clone()),
            doc_id,
        }
    }

    async fn open_doc(&mut self) {
        let flowy_document = self.flowy_test.sdk.flowy_document.clone();
        let pool = self.user_session.db_pool().unwrap();
        let doc_id = self.doc_id.clone();

        let edit_context = flowy_document.open(QueryDocParams { doc_id }, pool).await.unwrap();
        self.client_edit_context = Some(edit_context);
    }

    fn client_edit_context(&self) -> Arc<ClientEditDocContext> { self.client_edit_context.as_ref().unwrap().clone() }
}

impl Drop for ScriptContext {
    fn drop(&mut self) {
        // std::mem::forget(self.flowy_test);
    }
}

async fn run_scripts(context: Arc<RwLock<ScriptContext>>, scripts: Vec<DocScript>) {
    let mut fut_scripts = vec![];
    for script in scripts {
        let context = context.clone();
        let fut = async move {
            let doc_id = context.read().doc_id.clone();
            match script {
                DocScript::ConnectWs => {
                    // sleep(Duration::from_millis(300)).await;
                    let user_session = context.read().user_session.clone();
                    let token = user_session.token().unwrap();
                    let _ = user_session.start_ws_connection(&token).await.unwrap();
                },
                DocScript::OpenDoc => {
                    context.write().open_doc().await;
                },
                DocScript::InsertText(index, s) => {
                    context.read().client_edit_context().insert(index, s).await.unwrap();
                },
                DocScript::FormatText(interval, attribute) => {
                    context
                        .read()
                        .client_edit_context()
                        .format(interval, attribute)
                        .await
                        .unwrap();
                },
                DocScript::AssertClient(s) => {
                    sleep(Duration::from_millis(100)).await;
                    let json = context.read().client_edit_context().doc_json().await.unwrap();
                    assert_eq(s, &json);
                },
                DocScript::AssertServer(s, rev_id) => {
                    sleep(Duration::from_millis(100)).await;
                    let pg_pool = context.read().pool.clone();
                    let doc_manager = context.read().doc_manager.clone();
                    let edit_doc = doc_manager.get(&doc_id, pg_pool).await.unwrap().unwrap();
                    assert_eq!(edit_doc.rev_id().await.unwrap(), rev_id);
                    let json = edit_doc.document_json().await.unwrap();
                    assert_eq(s, &json);
                },
                DocScript::SetServerDocument(json, rev_id) => {
                    let pg_pool = context.read().pool.clone();
                    save_doc(&doc_id, json, rev_id, pg_pool).await;
                },
            }
        };
        fut_scripts.push(fut);
    }

    let mut stream = stream::iter(fut_scripts);
    while let Some(script) = stream.next().await {
        let _ = script.await;
    }

    std::mem::forget(context);
}

fn assert_eq(expect: &str, receive: &str) {
    if expect != receive {
        log::error!("expect: {}", expect);
        log::error!("but receive: {}", receive);
    }
    assert_eq!(expect, receive);
}

async fn create_doc(flowy_test: &FlowyTest) -> String {
    let view_test = ViewTest::new(flowy_test).await;
    let doc_id = view_test.view.id.clone();
    doc_id
}

async fn save_doc(doc_id: &str, json: String, rev_id: i64, pool: Data<PgPool>) {
    let mut params = UpdateDocParams::new();
    params.set_doc_id(doc_id.to_owned());
    params.set_data(json);
    params.set_rev_id(rev_id);
    let _ = update_doc(pool.get_ref(), params).await.unwrap();
}
