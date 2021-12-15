use crate::{helper::ViewTest, FlowySDKTest};
use flowy_collaboration::entities::{
    doc::DocIdentifier,
    ws::{WsDocumentData, WsDocumentDataBuilder},
};
use flowy_document::services::doc::{edit::ClientDocEditor, revision::RevisionIterator, SYNC_INTERVAL_IN_MILLIS};

use lib_ot::{
    core::Interval,
    revision::{RevState, RevType, Revision, RevisionRange},
    rich_text::RichTextDelta,
};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

pub enum EditorScript {
    StartWs,
    StopWs,
    InsertText(&'static str, usize),
    Delete(Interval),
    Replace(Interval, &'static str),
    Undo(),
    Redo(),
    WaitSyncFinished,
    SimulatePushRevisionMessageWithDelta(RichTextDelta),
    SimulatePullRevisionMessage(RevisionRange),
    SimulateAckedMessage(i64),
    AssertRevisionState(i64, RevState),
    AssertNextRevId(Option<i64>),
    AssertCurrentRevId(i64),
    AssertJson(&'static str),
}

pub struct EditorTest {
    pub sdk: FlowySDKTest,
    pub editor: Arc<ClientDocEditor>,
}

impl EditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::setup();
        let _ = sdk.init_user().await;
        let test = ViewTest::new(&sdk).await;
        let doc_identifier: DocIdentifier = test.view.id.clone().into();
        let editor = sdk.flowy_document.open(doc_identifier).await.unwrap();
        Self { sdk, editor }
    }

    pub async fn run_scripts(mut self, scripts: Vec<EditorScript>) {
        for script in scripts {
            self.run_script(script).await;
        }

        sleep(Duration::from_secs(5)).await;
    }

    async fn run_script(&mut self, script: EditorScript) {
        let rev_manager = self.editor.rev_manager();
        let cache = rev_manager.revision_cache();
        let _memory_cache = cache.memory_cache();
        let _disk_cache = cache.dish_cache();
        let doc_id = self.editor.doc_id.clone();
        let user_id = self.sdk.user_session.user_id().unwrap();
        let ws_manager = self.sdk.ws_manager.clone();
        let token = self.sdk.user_session.token().unwrap();

        match script {
            EditorScript::StartWs => {
                ws_manager.start(token.clone()).await.unwrap();
            },
            EditorScript::StopWs => {
                sleep(Duration::from_millis(SYNC_INTERVAL_IN_MILLIS)).await;
                ws_manager.stop().await;
            },
            EditorScript::InsertText(s, offset) => {
                self.editor.insert(offset, s).await.unwrap();
                sleep(Duration::from_millis(SYNC_INTERVAL_IN_MILLIS)).await;
            },
            EditorScript::Delete(interval) => {
                self.editor.delete(interval).await.unwrap();
            },
            EditorScript::Replace(interval, s) => {
                self.editor.replace(interval, s).await.unwrap();
            },
            EditorScript::Undo() => {
                self.editor.undo().await.unwrap();
            },
            EditorScript::Redo() => {
                self.editor.redo().await.unwrap();
            },
            EditorScript::WaitSyncFinished => {
                sleep(Duration::from_millis(1000)).await;
            },
            EditorScript::AssertRevisionState(rev_id, state) => {
                let record = cache.query_revision(&doc_id, rev_id).await.unwrap();
                assert_eq!(record.state, state);
            },
            EditorScript::AssertCurrentRevId(rev_id) => {
                assert_eq!(self.editor.rev_manager().rev_id(), rev_id);
            },
            EditorScript::AssertNextRevId(rev_id) => {
                let next_revision = cache.next().await.unwrap();
                if rev_id.is_none() {
                    assert_eq!(next_revision.is_none(), true);
                    return;
                }

                let next_revision = next_revision.unwrap();
                assert_eq!(next_revision.revision.rev_id, rev_id.unwrap());
            },
            EditorScript::SimulatePushRevisionMessageWithDelta(delta) => {
                let local_base_rev_id = rev_manager.rev_id();
                let local_rev_id = local_base_rev_id + 1;
                let revision = Revision::new(
                    local_base_rev_id,
                    local_rev_id,
                    delta.to_bytes().to_vec(),
                    &doc_id,
                    RevType::Remote,
                    user_id,
                );
                let data = WsDocumentDataBuilder::build_push_rev_message(&doc_id, revision);
                self.send_ws_message(data).await;
            },
            EditorScript::SimulatePullRevisionMessage(_range) => {},
            EditorScript::SimulateAckedMessage(i64) => {
                let data = WsDocumentDataBuilder::build_acked_message(&doc_id, i64);
                self.send_ws_message(data).await;
            },
            EditorScript::AssertJson(expected) => {
                let expected_delta: RichTextDelta = serde_json::from_str(expected).unwrap();
                let delta = self.editor.doc_delta().await.unwrap();

                if expected_delta != delta {
                    eprintln!("✅ expect: {}", expected,);
                    eprintln!("❌ receive: {}", delta.to_json());
                }
                assert_eq!(expected_delta, delta);
            },
        }
    }

    async fn send_ws_message(&self, data: WsDocumentData) {
        self.editor.handle_ws_message(data).await.unwrap();
        sleep(Duration::from_millis(200)).await;
    }
}
