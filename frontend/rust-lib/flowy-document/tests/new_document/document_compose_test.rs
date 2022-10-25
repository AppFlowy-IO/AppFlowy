use crate::new_document::script::DocumentEditorTest;
use crate::new_document::script::EditScript::*;

#[tokio::test]
async fn document_insert_h1_style_test() {
    let scripts = vec![
        ComposeTransactionStr {
            transaction: r#"{"operations":[{"op":"update_text","path":[0,0],"delta":[{"insert":"/"}],"inverted":[{"delete":1}]}],"after_selection":{"start":{"path":[0,0],"offset":1},"end":{"path":[0,0],"offset":1}},"before_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}}}"#,
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"text","delta":[{"insert":"/"}]}]}}"#,
        },
        ComposeTransactionStr {
            transaction: r#"{"operations":[{"op":"update_text","path":[0,0],"delta":[{"delete":1}],"inverted":[{"insert":"/"}]}],"after_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}},"before_selection":{"start":{"path":[0,0],"offset":1},"end":{"path":[0,0],"offset":1}}}"#,
        },
        ComposeTransactionStr {
            transaction: r#"{"operations":[{"op":"update","path":[0,0],"attributes":{"subtype":"heading","heading":"h1"},"oldAttributes":{"subtype":null,"heading":null}}],"after_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}},"before_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}}}"#,
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"text","attributes":{"subtype":"heading","heading":"h1"}}]}}"#,
        },
    ];
    DocumentEditorTest::new().await.run_scripts(scripts).await;
}
