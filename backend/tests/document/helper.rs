#![allow(clippy::all)]
#![cfg_attr(rustfmt, rustfmt::skip)]
use actix_web::web::Data;
use backend::service::doc::{crud::update_doc, manager::DocManager};
use backend_service::config::ServerConfig;
use flowy_document::services::doc::ClientDocEditor as ClientEditDocContext;
use flowy_test::{workspace::ViewTest, FlowyTest};
use flowy_user::services::user::UserSession;
use futures_util::{stream, stream::StreamExt};
use sqlx::PgPool;
use std::sync::Arc;
use tokio::time::{sleep, Duration};
// use crate::helper::*;
use crate::util::helper::{spawn_server, TestServer};
use flowy_document_infra::{entities::doc::DocIdentifier, protobuf::UpdateDocParams};
use lib_ot::core::{Attribute, Delta, Interval};
use parking_lot::RwLock;

pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowyTest,
}
#[derive(Clone)]
pub enum DocScript {
    ClientConnectWs,
    ClientInsertText(usize, &'static str),
    ClientFormatText(Interval, Attribute),
    ClientOpenDoc,
    AssertClient(&'static str),
    AssertServer(&'static str, i64),
    ServerSaveDocument(String, i64), // delta_json, rev_id
    Sleep(u64),
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
    client_user_session: Arc<UserSession>,
    server_doc_manager: Arc<DocManager>,
    server_pg_pool: Data<PgPool>,
    doc_id: String,
}

impl ScriptContext {
    async fn new(flowy_test: FlowyTest, server: TestServer) -> Self {
        let user_session = flowy_test.sdk.user_session.clone();
        let doc_id = create_doc(&flowy_test).await;

        Self {
            client_edit_context: None,
            flowy_test,
            client_user_session: user_session,
            server_doc_manager: server.app_ctx.doc_biz.manager.clone(),
            server_pg_pool: Data::new(server.pg_pool.clone()),
            doc_id,
        }
    }

    async fn open_doc(&mut self) {
        let flowy_document = self.flowy_test.sdk.flowy_document.clone();
        let doc_id = self.doc_id.clone();

        let edit_context = flowy_document.open(DocIdentifier { doc_id }).await.unwrap();
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
                DocScript::ClientConnectWs => {
                    // sleep(Duration::from_millis(300)).await;
                    let user_session = context.read().client_user_session.clone();
                    let token = user_session.token().unwrap();
                    let _ = user_session.start_ws_connection(&token).await.unwrap();
                },
                DocScript::ClientOpenDoc => {
                    context.write().open_doc().await;
                },
                DocScript::ClientInsertText(index, s) => {
                    context.read().client_edit_context().insert(index, s).await.unwrap();
                },
                DocScript::ClientFormatText(interval, attribute) => {
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
                    let pg_pool = context.read().server_pg_pool.clone();
                    let doc_manager = context.read().server_doc_manager.clone();
                    let edit_doc = doc_manager.get(&doc_id, pg_pool).await.unwrap().unwrap();
                    let json = edit_doc.document_json().await.unwrap();
                    assert_eq(s, &json);
                    assert_eq!(edit_doc.rev_id().await.unwrap(), rev_id);
                },
                DocScript::ServerSaveDocument(json, rev_id) => {
                    let pg_pool = context.read().server_pg_pool.clone();
                    save_doc(&doc_id, json, rev_id, pg_pool).await;
                },
                DocScript::Sleep(sec) => {
                    sleep(Duration::from_secs(sec)).await;
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
    let expected_delta: Delta = serde_json::from_str(expect).unwrap();
    let target_delta: Delta = serde_json::from_str(receive).unwrap();

    if expected_delta != target_delta {
        log::error!("✅ expect: {}", expect,);
        log::error!("❌ receive: {}", receive);
    }
    assert_eq!(target_delta, expected_delta);
}

async fn create_doc(flowy_test: &FlowyTest) -> String {
    let view_test = ViewTest::new(flowy_test).await;
    view_test.view.id
}

async fn save_doc(doc_id: &str, json: String, rev_id: i64, pool: Data<PgPool>) {
    let mut params = UpdateDocParams::new();
    params.set_doc_id(doc_id.to_owned());
    params.set_data(json);
    params.set_rev_id(rev_id);
    let _ = update_doc(pool.get_ref(), params).await.unwrap();
}
