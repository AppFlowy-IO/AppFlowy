use crate::util::unzip;
use assert_json_diff::assert_json_include;
use collab_database::rows::database_row_document_id_from_row_id;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_user::errors::ErrorCode;
use serde_json::{json, Value};
use std::env::temp_dir;

#[tokio::test]
async fn import_appflowy_data_need_migration_test() {
  // In 037, the workspace array will be migrated to view.
  let import_container_name = "037_local".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
  // Getting started
  //  Document1
  //  Document2(fav)
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  // workspace:
  //   view: Getting Started
  //   view: 037_local
  //      view: Getting Started
  //        view: Document1
  //        view: Document2

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[1].name, import_container_name);

  let child_views = test.get_view(&views[1].id).await.child_views;
  assert_eq!(child_views.len(), 1);

  let child_views = test.get_view(&child_views[0].id).await.child_views;
  assert_eq!(child_views.len(), 2);
  assert_eq!(child_views[0].name, "Document1");
  assert_eq!(child_views[1].name, "Document2");
  drop(cleaner);
}

#[tokio::test]
async fn import_appflowy_data_folder_into_new_view_test() {
  let import_container_name = "040_local".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
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
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  // workspace:
  //   view: Getting Started
  //   view: 040_local
  //     view: Document1
  //        view: Document2
  //          view: Grid1
  //          view: Grid2
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[1].name, import_container_name);

  // the 040_local should be an empty document, so try to get the document data
  let _ = test.get_document_data(&views[1].id).await;

  let local_child_views = test.get_view(&views[1].id).await.child_views;
  assert_eq!(local_child_views.len(), 1);
  assert_eq!(local_child_views[0].name, "Document1");

  let document1_child_views = test.get_view(&local_child_views[0].id).await.child_views;
  assert_eq!(document1_child_views.len(), 1);
  assert_eq!(document1_child_views[0].name, "Document2");

  let document2_child_views = test
    .get_view(&document1_child_views[0].id)
    .await
    .child_views;
  assert_eq!(document2_child_views.len(), 2);
  assert_eq!(document2_child_views[0].name, "Grid1");
  assert_eq!(document2_child_views[1].name, "Grid2");

  let rows = test.get_database(&document2_child_views[1].id).await.rows;
  assert_eq!(rows.len(), 3);

  // In the 040_local, only the first row has a document with content
  let row_document_id = database_row_document_id_from_row_id(&rows[0].id);
  let row_document_view = test.get_view(&row_document_id).await;
  assert_eq!(row_document_view.id, row_document_view.parent_view_id);

  let row_document_data = test.get_document_data(&row_document_id).await;
  assert_json_include!(actual: json!(row_document_data), expected: expected_row_doc_json());
  drop(cleaner);
}

#[tokio::test]
async fn import_appflowy_data_folder_into_current_workspace_test() {
  let import_container_name = "040_local".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
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
    .import_appflowy_data(user_db_path.to_str().unwrap().to_string(), None)
    .await
    .unwrap();
  // after import, the structure is:
  // workspace:
  //   view: Getting Started
  //   view: Document1
  //      view: Document2
  //        view: Grid1
  //        view: Grid2
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[1].name, "Document1");

  let document_1_child_views = test.get_view(&views[1].id).await.child_views;
  assert_eq!(document_1_child_views.len(), 1);
  assert_eq!(document_1_child_views[0].name, "Document2");

  let document2_child_views = test
    .get_view(&document_1_child_views[0].id)
    .await
    .child_views;
  assert_eq!(document2_child_views.len(), 2);
  assert_eq!(document2_child_views[0].name, "Grid1");
  assert_eq!(document2_child_views[1].name, "Grid2");

  drop(cleaner);
}

#[tokio::test]
async fn import_appflowy_data_folder_into_new_view_test2() {
  let import_container_name = "040_local_2".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[1].name, import_container_name);
  assert_040_local_2_import_content(&test, &views[1].id).await;

  drop(cleaner);
}

#[tokio::test]
async fn import_empty_appflowy_data_folder_test() {
  let path = temp_dir();
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  let error = test
    .import_appflowy_data(
      path.to_str().unwrap().to_string(),
      Some("empty_folder".to_string()),
    )
    .await
    .unwrap_err();
  assert_eq!(error.code, ErrorCode::AppFlowyDataFolderImportError);
}

#[tokio::test]
async fn import_appflowy_data_folder_multiple_times_test() {
  let import_container_name = "040_local_2".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
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
  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  //   Getting Started
  //   040_local_2

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 2);
  assert_eq!(views[1].name, import_container_name);
  assert_040_local_2_import_content(&test, &views[1].id).await;

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  //   Getting Started
  //   040_local_2
  //      Getting started
  //   040_local_2
  //      Getting started
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[2].name, import_container_name);
  assert_040_local_2_import_content(&test, &views[1].id).await;
  assert_040_local_2_import_content(&test, &views[2].id).await;
  drop(cleaner);
}

async fn assert_040_local_2_import_content(test: &EventIntegrationTest, view_id: &str) {
  //   040_local_2
  //      Getting started
  //         Doc1
  //         Doc2
  //         Grid1
  //         Doc3
  //            Doc3_grid_1
  //            Doc3_grid_2
  //            Doc3_calendar_1
  let _local_2_child_views = test.get_view(view_id).await.child_views;
  assert_eq!(_local_2_child_views.len(), 1);
  assert_eq!(_local_2_child_views[0].name, "Getting started");

  let local_2_getting_started_child_views =
    test.get_view(&_local_2_child_views[0].id).await.child_views;

  // Check doc 1 local content
  let doc_1 = local_2_getting_started_child_views[0].clone();
  assert_eq!(doc_1.name, "Doc1");
  let data = test.get_document_data(&doc_1.id).await;
  assert_json_include!(actual: json!(data), expected: expected_doc_1_json());

  // // Check doc 1 remote content
  // TODO(natan): enable these following lines
  // let doc_1_doc_state = test
  //   .get_collab_doc_state(&doc_1.id, CollabType::Document)
  //   .await
  //   .unwrap();
  // assert_json_include!(actual:document_data_from_document_doc_state(&doc_1.id, doc_1_doc_state), expected: expected_doc_1_json());

  // Check doc 2 local content
  let doc_2 = local_2_getting_started_child_views[1].clone();
  assert_eq!(doc_2.name, "Doc2");
  let data = test.get_document_data(&doc_2.id).await;
  assert_json_include!(actual: json!(data), expected: expected_doc_2_json());

  // Check doc 2 remote content
  // TODO(natan): enable these following lines
  // let doc_2_doc_state = test.get_document_doc_state(&doc_2.id).await;
  // assert_json_include!(actual:document_data_from_document_doc_state(&doc_2.id, doc_2_doc_state), expected: expected_doc_2_json());

  let grid_1 = local_2_getting_started_child_views[2].clone();
  assert_eq!(grid_1.name, "Grid1");
  // TODO(natan): enable these following lines
  // assert_eq!(
  //   test.get_database_export_data(&grid_1.id).await,
  //   "Name,Type,Done\n1,A,Yes\n2,,Yes\n3,,No\n"
  // );

  assert_eq!(local_2_getting_started_child_views[3].name, "Doc3");

  let doc_3_child_views = test
    .get_view(&local_2_getting_started_child_views[3].id)
    .await
    .child_views;
  assert_eq!(doc_3_child_views.len(), 3);
  assert_eq!(doc_3_child_views[0].name, "doc3_grid_1");

  let doc3_grid_2 = doc_3_child_views[1].clone();
  assert_eq!(doc3_grid_2.name, "doc3_grid_2");

  // TODO(natan): enable these following lines
  // assert_eq!(
  //   test.get_database_export_data(&doc3_grid_2.id).await,
  //   "Name,Type,Done\n1,A,Yes\n2,,\n,,\n"
  // );
  assert_eq!(doc_3_child_views[2].name, "doc3_calendar_1");
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

fn expected_row_doc_json() -> Value {
  json!( {
    "blocks": {
      "eSBQHZ28e0": {
        "children": "RbLAaE9UDJ",
        "data": {},
        "external_id": null,
        "external_type": null,
        "id": "eSBQHZ28e0",
        "parent": "",
        "ty": "page"
      },
      "eUIL6qjgj3": {
        "children": "fUnGRcvPEA",
        "data": {
          "delta": [
            {
              "insert": "document in database row"
            }
          ]
        },
        "external_id": "-DliEUjHr2",
        "external_type": "text",
        "id": "eUIL6qjgj3",
        "parent": "eSBQHZ28e0",
        "ty": "paragraph"
      }
    },
    "meta": {
      "children_map": {
        "RbLAaE9UDJ": [
          "eUIL6qjgj3"
        ],
        "fUnGRcvPEA": []
      },
      "text_map": {
        "-DliEUjHr2": "[{\"insert\":\"document in database row\"}]"
      }
    },
    "page_id": "eSBQHZ28e0"
  })
}
