use flowy_document::editor::{AppFlowyDocumentEditor, Document, DocumentTransaction};

use flowy_document::entities::DocumentVersionPB;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use lib_ot::core::{Body, Changeset, NodeDataBuilder, NodeOperation, Path, Transaction};
use lib_ot::text_delta::DeltaTextOperations;
use std::sync::Arc;

pub enum EditScript {
    InsertText {
        path: Path,
        delta: DeltaTextOperations,
    },
    UpdateText {
        path: Path,
        delta: DeltaTextOperations,
    },
    #[allow(dead_code)]
    ComposeTransaction {
        transaction: Transaction,
    },
    ComposeTransactionStr {
        transaction: &'static str,
    },
    Delete {
        path: Path,
    },
    AssertContent {
        expected: &'static str,
    },
    AssertPrettyContent {
        expected: &'static str,
    },
}

pub struct DocumentEditorTest {
    pub sdk: FlowySDKTest,
    pub editor: Arc<AppFlowyDocumentEditor>,
}

impl DocumentEditorTest {
    pub async fn new() -> Self {
        let version = DocumentVersionPB::V1;
        let sdk = FlowySDKTest::new(version.clone());
        let _ = sdk.init_user().await;

        let test = ViewTest::new_document_view(&sdk).await;
        let document_editor = sdk.document_manager.open_document_editor(&test.view.id).await.unwrap();
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
            EditScript::ComposeTransaction { transaction } => {
                self.editor.apply_transaction(transaction).await.unwrap();
            }
            EditScript::ComposeTransactionStr { transaction } => {
                let document_transaction = serde_json::from_str::<DocumentTransaction>(transaction).unwrap();
                let transaction: Transaction = document_transaction.into();
                self.editor.apply_transaction(transaction).await.unwrap();
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
                let expected_document: Document = serde_json::from_str(expected).unwrap();
                let expected = serde_json::to_string(&expected_document).unwrap();

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
