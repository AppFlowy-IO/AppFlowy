use crate::util::unzip_history_user_db;
use assert_json_diff::assert_json_include;
use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use serde_json::{json, Value};

#[tokio::test]
async fn import_appflowy_data_folder_test() {
  let import_container_name = "040_local".to_string();
  let (cleaner, user_db_path) =
    unzip_history_user_db("./tests/asset", &import_container_name).unwrap();
  // In the 040_local, the structure is:
  // workspace:
  //  view: Document1
  //    view: Document2
  //      view: Grid1
  //      view: Grid2
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  // after sign up, the initial workspace is created, so the structure is:
  // workspace:
  //   view: Getting Started

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      &import_container_name,
    )
    .await;
  // after import, the structure is:
  // workspace:
  //   view: Getting Started
  //   view: 040_local
  //     view: Document1
  //        view: Document2
  //          view: Grid1
  //          view: Grid2
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 2);
  assert_eq!(views[1].name, import_container_name);

  let local_child_views = test.get_views(&views[1].id).await.child_views;
  assert_eq!(local_child_views.len(), 1);
  assert_eq!(local_child_views[0].name, "Document1");

  let document1_child_views = test.get_views(&local_child_views[0].id).await.child_views;
  assert_eq!(document1_child_views.len(), 1);
  assert_eq!(document1_child_views[0].name, "Document2");

  let document2_child_views = test
    .get_views(&document1_child_views[0].id)
    .await
    .child_views;
  assert_eq!(document2_child_views.len(), 2);
  assert_eq!(document2_child_views[0].name, "Grid1");
  assert_eq!(document2_child_views[1].name, "Grid2");

  drop(cleaner);
}

#[tokio::test]
async fn import_appflowy_data_folder_test2() {
  let import_container_name = "040_local_2".to_string();
  let (cleaner, user_db_path) =
    unzip_history_user_db("./tests/asset", &import_container_name).unwrap();
  // In the 040_local_2, the structure is:
  //  Getting Started
  //     Doc1
  //     Doc2
  //     Grid1
  //     Doc3
  //        Doc3_grid_1
  //        Doc3_grid_2
  //        Doc3_calendar_1
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  // after sign up, the initial workspace is created, so the structure is:
  // workspace:
  //   view: Getting Started

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      &import_container_name,
    )
    .await;
  // after import, the structure is:
  //   Getting Started
  //   040_local_2
  //      Getting started
  //         Doc1
  //         Doc2
  //         Grid1
  //         Doc3
  //            Doc3_grid_1
  //            Doc3_grid_2
  //            Doc3_calendar_1

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 2);
  assert_eq!(views[1].name, import_container_name);

  let _local_2_child_views = test.get_views(&views[1].id).await.child_views;
  assert_eq!(_local_2_child_views.len(), 1);
  assert_eq!(_local_2_child_views[0].name, "Getting started");

  let local_2_getting_started_child_views = test
    .get_views(&_local_2_child_views[0].id)
    .await
    .child_views;

  let doc_1 = local_2_getting_started_child_views[0].clone();
  assert_eq!(doc_1.name, "Doc1");
  let data = test.get_document_data(&doc_1.id).await;
  assert_json_include!(actual: json!(data), expected: expected_doc_1_json());

  let doc_2 = local_2_getting_started_child_views[1].clone();
  assert_eq!(doc_2.name, "Doc2");
  let data = test.get_document_data(&doc_2.id).await;
  assert_json_include!(actual: json!(data), expected: expected_doc_2_json());

  let grid_1 = local_2_getting_started_child_views[2].clone();
  assert_eq!(grid_1.name, "Grid1");
  assert_eq!(test.get_database_export_data(&grid_1.id).await, "");

  assert_eq!(local_2_getting_started_child_views[3].name, "Doc3");

  let doc_3_child_views = test
    .get_views(&local_2_getting_started_child_views[3].id)
    .await
    .child_views;
  assert_eq!(doc_3_child_views.len(), 3);
  assert_eq!(doc_3_child_views[0].name, "doc3_grid_1");
  assert_eq!(doc_3_child_views[1].name, "doc3_grid_2");
  assert_eq!(doc_3_child_views[2].name, "doc3_calendar_1");

  drop(cleaner);
}

fn expected_doc_1_json() -> Value {
  json!({
    "blocks": {
      "Rnslggtr6s": {
        "children": "CoT14jXwTV",
        "data": {
          "delta": [
            {
              "insert": "Hello Document 1"
            }
          ]
        },
        "external_id": "hUDq6PrdP1",
        "external_type": "text",
        "id": "Rnslggtr6s",
        "parent": "vxWayiyi2Q",
        "ty": "paragraph"
      },
      "vxWayiyi2Q": {
        "children": "hAgnEMJtU2",
        "data": {},
        "external_id": null,
        "external_type": null,
        "id": "vxWayiyi2Q",
        "parent": "",
        "ty": "page"
      }
    },
    "meta": {
      "children_map": {
        "CoT14jXwTV": [],
        "hAgnEMJtU2": [
          "Rnslggtr6s"
        ]
      },
      "text_map": {
        "hUDq6PrdP1": "[{\"insert\":\"Hello Document 1\"}]",
        "ujncfD": "[]"
      }
    },
    "page_id": "vxWayiyi2Q"
  })
}
fn expected_doc_2_json() -> Value {
  json!({
    "blocks": {
      "ZVogdaK9yO": {
        "children": "cc20wCE77N",
        "data": {},
        "external_id": null,
        "external_type": null,
        "id": "ZVogdaK9yO",
        "parent": "",
        "ty": "page"
      },
      "bVRuGAvyfp": {
        "children": "pOVd5xKBal",
        "data": {
          "delta": [
            {
              "insert": "Hello Document 2"
            }
          ]
        },
        "external_id": "m7mwLgXzDF",
        "external_type": "text",
        "id": "bVRuGAvyfp",
        "parent": "ZVogdaK9yO",
        "ty": "paragraph"
      },
      "ng2b4I": {
        "children": "YMaDFs",
        "data": {
          "delta": []
        },
        "external_id": null,
        "external_type": null,
        "id": "ng2b4I",
        "parent": "ZVogdaK9yO",
        "ty": "paragraph"
      }
    },
    "meta": {
      "children_map": {
        "YMaDFs": [],
        "cc20wCE77N": [
          "bVRuGAvyfp",
          "ng2b4I"
        ],
        "pOVd5xKBal": []
      },
      "text_map": {
        "m7mwLgXzDF": "[{\"insert\":\"Hello Document 2\"}]",
        "qXQmuS": "[]"
      }
    },
    "page_id": "ZVogdaK9yO"
  })
}
