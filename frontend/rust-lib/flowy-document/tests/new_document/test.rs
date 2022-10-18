use crate::new_document::script::DocumentEditorTest;
use crate::new_document::script::EditScript::*;
use lib_ot::core::{DeltaBuilder, DeltaOperations, Path};
use lib_ot::text_delta::TextOperationBuilder;

#[tokio::test]
async fn test() {
    let init_delta = TextOperationBuilder::new().insert("Hello world").build();
    let scripts = vec![
        InsertText {
            path: 0.into(),
            delta: init_delta,
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"update_text","body":{"delta":[{"insert":"abc"}]}}]}}"#,
        },
    ];

    DocumentEditorTest::new().await.run_scripts(scripts).await;
}
