use flowy_document::editor::AppFlowyDocumentEditor;

use flowy_document::entities::DocumentTypePB;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use lib_ot::core::{Body, Changeset, NodeDataBuilder, NodeOperation, Path, Transaction};
use lib_ot::text_delta::TextOperations;
use std::sync::Arc;

pub enum EditScript {
    InsertText { path: Path, delta: TextOperations },
    UpdateText { path: Path, delta: TextOperations },
    Delete { path: Path },
    AssertContent { expected: &'static str },
    AssertPrettyContent { expected: &'static str },
}

pub struct DocumentEditorTest {
    pub sdk: FlowySDKTest,
    pub editor: Arc<AppFlowyDocumentEditor>,
}

impl DocumentEditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::new(true);
        let _ = sdk.init_user().await;

        let test = ViewTest::new_document_view(&sdk).await;
        let document_editor = sdk
            .document_manager
            .open_document_editor(&test.view.id, DocumentTypePB::NodeTree)
            .await
            .unwrap();
        let editor = match document_editor.as_any().downcast_ref::<Arc<AppFlowyDocumentEditor>>() {
            None => panic!(),
            Some(editor) => editor.clone(),
        };

        Self { sdk, editor }
    }

    pub async fn run_scripts(&self, scripts: Vec<EditScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    async fn run_script(&self, script: EditScript) {
        match script {
            EditScript::InsertText { path, delta } => {
                let node_data = NodeDataBuilder::new("text").insert_body(Body::Delta(delta)).build();
                let operation = NodeOperation::Insert {
                    path,
                    nodes: vec![node_data],
                };
                self.editor
                    .apply_transaction(Transaction::from_operations(vec![operation]))
                    .await
                    .unwrap();
            }
            EditScript::UpdateText { path, delta } => {
                let inverted = delta.invert_str("");
                let changeset = Changeset::Delta { delta, inverted };
                let operation = NodeOperation::Update { path, changeset };
                self.editor
                    .apply_transaction(Transaction::from_operations(vec![operation]))
                    .await
                    .unwrap();
            }
            EditScript::Delete { path } => {
                let operation = NodeOperation::Delete { path, nodes: vec![] };
                self.editor
                    .apply_transaction(Transaction::from_operations(vec![operation]))
                    .await
                    .unwrap();
            }
            EditScript::AssertContent { expected } => {
                //
                let content = self.editor.get_content(false).await.unwrap();
                assert_eq!(content, expected);
            }
            EditScript::AssertPrettyContent { expected } => {
                //
                let content = self.editor.get_content(true).await.unwrap();
                assert_eq!(content, expected);
            }
        }
    }
}
