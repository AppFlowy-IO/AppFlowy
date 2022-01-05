#![allow(clippy::all)]
#![cfg_attr(rustfmt, rustfmt::skip)]
use std::convert::TryInto;
use actix_web::web::Data;
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
use flowy_document::services::doc::edit::ClientDocumentEditor;
=======
use flowy_document::core::edit::ClientDocumentEditor;
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
use flowy_test::{helper::ViewTest, FlowySDKTest};
use flowy_user::services::user::UserSession;
use futures_util::{stream, stream::StreamExt};
use std::sync::Arc;
use bytes::Bytes;
use tokio::time::{sleep, Duration};
use crate::util::helper::{spawn_server, TestServer};
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
use flowy_collaboration::{entities::doc::DocumentId, protobuf::ResetDocumentParams};
use lib_ot::rich_text::{RichTextAttribute, RichTextDelta};
use parking_lot::RwLock;
use backend::services::document::persistence::{DocumentKVPersistence, read_document, reset_document};
use flowy_collaboration::entities::revision::{RepeatedRevision, Revision};
=======
use flowy_collaboration::{entities::doc::DocumentId, protobuf::ResetDocumentParams as ResetDocumentParamsPB};
use lib_ot::rich_text::{RichTextAttribute, RichTextDelta};
use parking_lot::RwLock;
use backend::services::document::persistence::{read_document, reset_document};
use flowy_collaboration::entities::revision::{RepeatedRevision, Revision};
use flowy_collaboration::protobuf::{RepeatedRevision as RepeatedRevisionPB, DocumentId as DocumentIdPB};
use flowy_collaboration::sync::ServerDocumentManager;
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
use lib_ot::core::Interval;

use flowy_net::services::ws::FlowyWSConnect;


pub struct DocumentTest {
    server: TestServer,
    flowy_test: FlowySDKTest,
}
#[derive(Clone)]
pub enum DocScript {
    ClientInsertText(usize, &'static str),
    ClientFormatText(Interval, RichTextAttribute),
    ClientOpenDoc,
    AssertClient(&'static str),
    AssertServer(&'static str, i64),
    ServerResetDocument(String, i64), // delta_json, rev_id
}

impl DocumentTest {
    pub async fn new() -> Self {
        let server = spawn_server().await;
        let flowy_test = FlowySDKTest::setup_with(server.client_server_config.clone());
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
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
    client_edit_context: Option<Arc<ClientDocumentEditor>>,
=======
    client_editor: Option<Arc<ClientDocumentEditor>>,
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
    client_sdk: FlowySDKTest,
    client_user_session: Arc<UserSession>,
    ws_conn: Arc<FlowyWSConnect>,
    server: TestServer,
    doc_id: String,
}

impl ScriptContext {
    async fn new(client_sdk: FlowySDKTest, server: TestServer) -> Self {
        let user_session = client_sdk.user_session.clone();
        let ws_manager = client_sdk.ws_manager.clone();
        let doc_id = create_doc(&client_sdk).await;

        Self {
            client_editor: None,
            client_sdk,
            client_user_session: user_session,
            ws_conn: ws_manager,
            server,
            doc_id,
        }
    }

    async fn open_doc(&mut self) {
        let doc_id = self.doc_id.clone();
        let edit_context = self.client_sdk.document_ctx.controller.open(doc_id).await.unwrap();
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
        self.client_edit_context = Some(edit_context);
    }

    fn client_edit_context(&self) -> Arc<ClientDocumentEditor> { self.client_edit_context.as_ref().unwrap().clone() }
=======
        self.client_editor = Some(edit_context);
    }

    fn client_editor(&self) -> Arc<ClientDocumentEditor> { self.client_editor.as_ref().unwrap().clone() }
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
}

async fn run_scripts(context: Arc<RwLock<ScriptContext>>, scripts: Vec<DocScript>) {
    let mut fut_scripts = vec![];
    for script in scripts {
        let context = context.clone();
        let fut = async move {
            let doc_id = context.read().doc_id.clone();
            match script {
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
                DocScript::ClientConnectWS => {
                    // sleep(Duration::from_millis(300)).await;
                    let ws_manager = context.read().ws_conn.clone();
                    let user_session = context.read().client_user_session.clone();
                    let token = user_session.token().unwrap();
                    let _ = ws_manager.start(token).await.unwrap();
                },
=======
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
                DocScript::ClientOpenDoc => {
                    context.write().open_doc().await;
                },
                DocScript::ClientInsertText(index, s) => {
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
                    sleep(Duration::from_millis(2000)).await;
                    context.read().client_edit_context().insert(index, s).await.unwrap();
=======
                    context.read().client_editor().insert(index, s).await.unwrap();
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
                },
                DocScript::ClientFormatText(interval, attribute) => {
                    context
                        .read()
                        .client_editor()
                        .format(interval, attribute)
                        .await
                        .unwrap();
                },
                DocScript::AssertClient(s) => {
                    sleep(Duration::from_millis(2000)).await;
                    let json = context.read().client_editor().doc_json().await.unwrap();
                    assert_eq(s, &json);
                },
                DocScript::AssertServer(s, rev_id) => {
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
                    sleep(Duration::from_millis(100)).await;
                    let persistence = Data::new(context.read().server.app_ctx.persistence.kv_store());
                    let doc_identifier: flowy_collaboration::protobuf::DocumentId = DocumentId {
=======
                    sleep(Duration::from_millis(2000)).await;
                    let persistence = Data::new(context.read().server.app_ctx.persistence.kv_store());
                    let doc_identifier: DocumentIdPB = DocumentId {
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
                        doc_id
                    }.try_into().unwrap();
                    
                    let document_info = read_document(persistence.get_ref(), doc_identifier).await.unwrap();
                    assert_eq(s, &document_info.text);
                    assert_eq!(document_info.rev_id, rev_id);
                },
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
                DocScript::ServerSaveDocument(document_json, rev_id) => {
=======
                DocScript::ServerResetDocument(document_json, rev_id) => {
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
                    let delta_data = Bytes::from(document_json);
                    let user_id = context.read().client_user_session.user_id().unwrap();
                    let md5 = format!("{:x}", md5::compute(&delta_data));
                    let base_rev_id = if rev_id == 0 { rev_id } else { rev_id - 1 };
                    let revision = Revision::new(
                        &doc_id,
                        base_rev_id,
                        rev_id,
                        delta_data,
                        &user_id,
                        md5,
                    );
                    
<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
                    let kv_store = Data::new(context.read().server.app_ctx.persistence.kv_store());
                    reset_doc(&doc_id, RepeatedRevision::new(vec![revision]), kv_store.get_ref()).await;
=======
                    let document_manager = context.read().server.app_ctx.document_manager.clone();
                    reset_doc(&doc_id, RepeatedRevision::new(vec![revision]), document_manager.get_ref()).await;
                    sleep(Duration::from_millis(2000)).await;
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
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
    let expected_delta: RichTextDelta = serde_json::from_str(expect).unwrap();
    let target_delta: RichTextDelta = serde_json::from_str(receive).unwrap();

    if expected_delta != target_delta {
        log::error!("✅ expect: {}", expect,);
        log::error!("❌ receive: {}", receive);
    }
    assert_eq!(target_delta, expected_delta);
}

async fn create_doc(flowy_test: &FlowySDKTest) -> String {
    let view_test = ViewTest::new(flowy_test).await;
    view_test.view.id
}

<<<<<<< HEAD:backend/tests/document_test/edit_script.rs
async fn reset_doc(doc_id: &str, repeated_revision: RepeatedRevision, kv_store: &Arc<DocumentKVPersistence>) {
    let pb: flowy_collaboration::protobuf::RepeatedRevision = repeated_revision.try_into().unwrap();
    let mut params = ResetDocumentParams::new();
    params.set_doc_id(doc_id.to_owned());
    params.set_revisions(pb);
    let _ = reset_document(kv_store, params).await.unwrap();
=======
async fn reset_doc(doc_id: &str, repeated_revision: RepeatedRevision, document_manager: &Arc<ServerDocumentManager>) {
    let pb: RepeatedRevisionPB = repeated_revision.try_into().unwrap();
    let mut params = ResetDocumentParamsPB::new();
    params.set_doc_id(doc_id.to_owned());
    params.set_revisions(pb);
    let _ = reset_document(document_manager, params).await.unwrap();
>>>>>>> upstream/main:backend/tests/document/edit_script.rs
}
