use crate::new_document::script::DocumentEditorTest;
use crate::new_document::script::EditScript::*;

use lib_ot::text_delta::TextOperationBuilder;

#[tokio::test]
async fn document_initialize_test() {
    let scripts = vec![AssertContent {
        expected: r#"{"document":{"type":"editor","children":[{"type":"text"}]}}"#,
    }];
    DocumentEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_insert_text_test() {
    let delta = TextOperationBuilder::new().insert("Hello world").build();
    let expected = r#"{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "text",
        "delta": [
          {
            "insert": "Hello world"
          }
        ]
      },
      {
        "type": "text"
      }
    ]
  }
}"#;
    let scripts = vec![
        InsertText {
            path: vec![0, 0].into(),
            delta,
        },
        AssertPrettyContent { expected },
    ];
    DocumentEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_update_text_test() {
    let test = DocumentEditorTest::new().await;
    let hello_world = "Hello world".to_string();
    let scripts = vec![
        UpdateText {
            path: vec![0, 0].into(),
            delta: TextOperationBuilder::new().insert(&hello_world).build(),
        },
        AssertPrettyContent {
            expected: r#"{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "text",
        "delta": [
          {
            "insert": "Hello world"
          }
        ]
      }
    ]
  }
}"#,
        },
    ];

    test.run_scripts(scripts).await;

    let scripts = vec![
        UpdateText {
            path: vec![0, 0].into(),
            delta: TextOperationBuilder::new()
                .retain(hello_world.len())
                .insert(", AppFlowy")
                .build(),
        },
        AssertPrettyContent {
            expected: r#"{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "text",
        "delta": [
          {
            "insert": "Hello world, AppFlowy"
          }
        ]
      }
    ]
  }
}"#,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_delete_text_test() {
    let expected = r#"{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "text",
        "delta": [
          {
            "insert": "Hello"
          }
        ]
      }
    ]
  }
}"#;
    let hello_world = "Hello world".to_string();
    let scripts = vec![
        UpdateText {
            path: vec![0, 0].into(),
            delta: TextOperationBuilder::new().insert(&hello_world).build(),
        },
        UpdateText {
            path: vec![0, 0].into(),
            delta: TextOperationBuilder::new().retain(5).delete(6).build(),
        },
        AssertPrettyContent { expected },
    ];

    DocumentEditorTest::new().await.run_scripts(scripts).await;
}

#[tokio::test]
async fn document_delete_node_test() {
    let scripts = vec![
        UpdateText {
            path: vec![0, 0].into(),
            delta: TextOperationBuilder::new().insert("Hello world").build(),
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor","children":[{"type":"text","delta":[{"insert":"Hello world"}]}]}}"#,
        },
        Delete {
            path: vec![0, 0].into(),
        },
        AssertContent {
            expected: r#"{"document":{"type":"editor"}}"#,
        },
    ];

    DocumentEditorTest::new().await.run_scripts(scripts).await;
}
