use crate::new_document::script::DocumentEditorTest;
use crate::new_document::script::EditScript::*;
use lib_ot::core::{DeltaBuilder, DeltaOperations, Path};
use lib_ot::text_delta::TextOperationBuilder;

#[tokio::test]
async fn document_initialize_test() {
    let scripts = vec![AssertContent {
        expected: r#"{"document":{"type":"editor","children":[{"type":"text","body":{"delta":[]}}]}}"#,
    }];
    DocumentEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_insert_text_test() {
    let delta = TextOperationBuilder::new().insert("Hello world").build();
    let scripts = vec![
        InsertText {
            path: vec![0, 0].into(),
            delta,
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"update_text","body":{"delta":[{"insert":"Hello world"}]}},{"type":"text","body":{"delta":[]}}]}}"#,
        },
    ];
    DocumentEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_update_text_test() {
    let delta = TextOperationBuilder::new().insert("Hello world").build();
    let scripts = vec![
        UpdateText {
            path: vec![0, 0].into(),
            delta,
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"text","body":{"delta":[{"insert":"Hello world"}]}}]}}"#,
        },
    ];

    DocumentEditorTest::new().await.run_scripts(scripts).await;
}
