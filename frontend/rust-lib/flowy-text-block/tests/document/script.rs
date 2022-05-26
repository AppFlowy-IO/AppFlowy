use flowy_revision::disk::RevisionState;
use flowy_test::{helper::ViewTest, FlowySDKTest};
use flowy_text_block::editor::TextBlockEditor;
use flowy_text_block::TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS;
use lib_ot::{core::Interval, rich_text::RichTextDelta};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

pub enum EditorScript {
    InsertText(&'static str, usize),
    Delete(Interval),
    Replace(Interval, &'static str),

    AssertRevisionState(i64, RevisionState),
    AssertNextSyncRevId(Option<i64>),
    AssertCurrentRevId(i64),
    AssertJson(&'static str),
}

pub struct TextBlockEditorTest {
    pub sdk: FlowySDKTest,
    pub editor: Arc<TextBlockEditor>,
}

impl TextBlockEditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let test = ViewTest::new_text_block_view(&sdk).await;
        let editor = sdk.text_block_manager.open_block(&test.view.id).await.unwrap();
        Self { sdk, editor }
    }

    pub async fn run_scripts(mut self, scripts: Vec<EditorScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    async fn run_script(&mut self, script: EditorScript) {
        let rev_manager = self.editor.rev_manager();
        let cache = rev_manager.revision_cache().await;
        let _user_id = self.sdk.user_session.user_id().unwrap();

        match script {
            EditorScript::InsertText(s, offset) => {
                self.editor.insert(offset, s).await.unwrap();
            }
            EditorScript::Delete(interval) => {
                self.editor.delete(interval).await.unwrap();
            }
            EditorScript::Replace(interval, s) => {
                self.editor.replace(interval, s).await.unwrap();
            }
            EditorScript::AssertRevisionState(rev_id, state) => {
                let record = cache.get(rev_id).await.unwrap();
                assert_eq!(record.state, state);
            }
            EditorScript::AssertCurrentRevId(rev_id) => {
                assert_eq!(self.editor.rev_manager().rev_id(), rev_id);
            }
            EditorScript::AssertNextSyncRevId(rev_id) => {
                let next_revision = rev_manager.next_sync_revision().await.unwrap();
                if rev_id.is_none() {
                    assert!(next_revision.is_none(), "Next revision should be None");
                    return;
                }
                let next_revision = next_revision.unwrap();
                let mut notify = rev_manager.ack_notify();
                let _ = notify.recv().await;
                assert_eq!(next_revision.rev_id, rev_id.unwrap());
            }
            EditorScript::AssertJson(expected) => {
                let expected_delta: RichTextDelta = serde_json::from_str(expected).unwrap();
                let delta = self.editor.text_block_delta().await.unwrap();
                if expected_delta != delta {
                    eprintln!("✅ expect: {}", expected,);
                    eprintln!("❌ receive: {}", delta.to_delta_str());
                }
                assert_eq!(expected_delta, delta);
            }
        }
        sleep(Duration::from_millis(TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS)).await;
    }
}
