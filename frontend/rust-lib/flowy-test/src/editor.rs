use crate::{helper::ViewTest, FlowySDKTest};
use flowy_document::services::doc::edit::ClientDocEditor;
use flowy_document_infra::entities::doc::DocIdentifier;
use lib_ot::{core::Interval, revision::RevState, rich_text::RichTextDelta};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

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

        sleep(Duration::from_secs(10)).await;
    }

    async fn run_script(&mut self, script: EditorScript) {
        let rev_manager = self.editor.rev_manager();
        let cache = rev_manager.revision_cache();
        let memory_cache = cache.memory_cache();
        let disk_cache = cache.dish_cache();

        match script {
            EditorScript::InsertText(s, offset) => {
                self.editor.insert(offset, s).await.unwrap();
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
            EditorScript::AssertRevisionState(rev_id, state) => {},
            EditorScript::AssertNextSentRevision(rev_id, state) => {},
            EditorScript::AssertRevId(rev_id) => {
                assert_eq!(self.editor.rev_manager().rev_id(), rev_id);
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
}

pub enum EditorScript {
    InsertText(&'static str, usize),
    Delete(Interval),
    Replace(Interval, &'static str),
    Undo(),
    Redo(),
    AssertRevisionState(i64, RevState),
    AssertNextSentRevision(i64, RevState),
    AssertRevId(i64),
    AssertJson(&'static str),
}
