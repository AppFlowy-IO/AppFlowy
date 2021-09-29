// use crate::helper::*;
use crate::helper::{spawn_server, TestServer};

use actix_web::web::Data;
use flowy_document::{
    entities::doc::QueryDocParams,
    services::doc::edit_doc_context::EditDocContext as ClientEditDocContext,
};
use flowy_net::config::ServerConfig;
use flowy_test::{workspace::ViewTest, FlowyTest};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowyTest,
}
#[derive(Clone)]
pub enum DocScript {
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
        init_user(&self.flowy_test).await;
        let DocumentTest { server, flowy_test } = self;
        run_scripts(server, flowy_test, scripts).await;
        sleep(Duration::from_secs(5)).await;
    }
}

pub async fn run_scripts(server: TestServer, flowy_test: FlowyTest, scripts: Vec<DocScript>) {
    let client_edit_context = create_doc(&flowy_test).await;
    let doc_id = client_edit_context.doc_id.clone();
    for script in scripts {
        match script {
            DocScript::SendText(index, s) => {
                client_edit_context.insert(index, s);
            },
            DocScript::AssertClient(s) => {
                let json = client_edit_context.doc_json();
                assert_eq(s, &json);
            },
            DocScript::AssertServer(s) => {
                sleep(Duration::from_millis(100)).await;
                let pool = server.pg_pool.clone();
                let edit_context = server
                    .app_ctx
                    .doc_biz
                    .manager
                    .get(&doc_id, Data::new(pool))
                    .await
                    .unwrap()
                    .unwrap();
                let json = edit_context.doc_json();
                assert_eq(s, &json);
            },
        }
    }
    std::mem::forget(flowy_test);
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

async fn init_user(flowy_test: &FlowyTest) {
    let _ = flowy_test.sign_up().await;

    let user_session = flowy_test.sdk.user_session.clone();
    user_session.init_user().await.unwrap();
}
