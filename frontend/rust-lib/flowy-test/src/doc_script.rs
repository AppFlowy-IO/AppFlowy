use crate::{helper::ViewTest, FlowySDKTest};
use flowy_collaboration::entities::revision::RevisionState;
use flowy_document::services::doc::{edit::ClientDocumentEditor, SYNC_INTERVAL_IN_MILLIS};
use lib_ot::{core::Interval, rich_text::RichTextDelta};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

pub enum EditorScript {
    StartWs,
    StopWs,
    InsertText(&'static str, usize),
    Delete(Interval),
    Replace(Interval, &'static str),

    AssertRevisionState(i64, RevisionState),
    AssertNextRevId(Option<i64>),
    AssertCurrentRevId(i64),
    AssertJson(&'static str),

    WaitSyncFinished,
}

pub struct EditorTest {
    pub sdk: FlowySDKTest,
    pub editor: Arc<ClientDocumentEditor>,
}

impl EditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::setup();
        let _ = sdk.init_user().await;
        let test = ViewTest::new(&sdk).await;
        let editor = sdk.document_ctx.controller.open(&test.view.id).await.unwrap();
        Self { sdk, editor }
    }

    pub async fn run_scripts(mut self, scripts: Vec<EditorScript>) {
        for script in scripts {
            self.run_script(script).await;
        }

        sleep(Duration::from_secs(3)).await;
    }

    async fn run_script(&mut self, script: EditorScript) {
        let rev_manager = self.editor.rev_manager();
        let cache = rev_manager.revision_cache();
        let _user_id = self.sdk.user_session.user_id().unwrap();
        let ws_manager = self.sdk.ws_manager.clone();
        let token = self.sdk.user_session.token().unwrap();
        let wait_millis = 2 * SYNC_INTERVAL_IN_MILLIS;

        match script {
            EditorScript::StartWs => {
                ws_manager.start(token.clone()).await.unwrap();
            },
            EditorScript::StopWs => {
                ws_manager.stop().await;
            },
            EditorScript::InsertText(s, offset) => {
                self.editor.insert(offset, s).await.unwrap();
            },
            EditorScript::Delete(interval) => {
                self.editor.delete(interval).await.unwrap();
            },
            EditorScript::Replace(interval, s) => {
                self.editor.replace(interval, s).await.unwrap();
            },
            EditorScript::AssertRevisionState(rev_id, state) => {
                let record = cache.get_revision(rev_id).await.unwrap();
                assert_eq!(record.state, state);
            },
            EditorScript::AssertCurrentRevId(rev_id) => {
                assert_eq!(self.editor.rev_manager().rev_id(), rev_id);
            },
            EditorScript::AssertNextRevId(rev_id) => {
                let next_revision = rev_manager.next_sync_revision().await.unwrap();
                if rev_id.is_none() {
                    assert_eq!(next_revision.is_none(), true, "Next revision should be None");
                    return;
                }
                let next_revision = next_revision.unwrap();
                assert_eq!(next_revision.rev_id, rev_id.unwrap());
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
            EditorScript::WaitSyncFinished => {
                // Workaround: just wait two seconds
                sleep(Duration::from_millis(2000)).await;
            },
        }
        sleep(Duration::from_millis(wait_millis)).await;
    }
}
