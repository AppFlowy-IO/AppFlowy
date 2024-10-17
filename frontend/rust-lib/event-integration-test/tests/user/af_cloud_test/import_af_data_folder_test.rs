use crate::util::unzip;
use assert_json_diff::assert_json_include;
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::preclude::{Any, Collab};
use collab_database::rows::database_row_document_id_from_row_id;
use collab_document::blocks::TextDelta;
use collab_document::document::Document;
use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder::entities::ViewLayoutPB;
use flowy_user::errors::ErrorCode;
use serde_json::{json, Value};
use std::env::temp_dir;

#[tokio::test]
async fn import_appflowy_data_with_ref_views_test() {
  let import_container_name = "data_ref_doc".to_string();
  let (_cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  let views = test.get_all_workspace_views().await;
  let shared_space_id = views[1].id.clone();
  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();

  let general_space = test.get_view(&shared_space_id).await;
  let shared_sub_views = &general_space.child_views;
  assert_eq!(shared_sub_views.len(), 1);
  assert_eq!(shared_sub_views[0].name, import_container_name);

  let imported_view_id = shared_sub_views[0].id.clone();
  let imported_sub_views = test.get_view(&imported_view_id).await.child_views;
  assert_eq!(imported_sub_views.len(), 1);

  let imported_get_started_view_id = imported_sub_views[0].id.clone();
  let doc_state = test
    .get_document_doc_state(&imported_get_started_view_id)
    .await;
  let collab = Collab::new_with_source(
    CollabOrigin::Empty,
    &imported_get_started_view_id,
    DataSource::DocStateV1(doc_state),
    vec![],
    false,
  )
  .unwrap();
  let document = Document::open(collab).unwrap();

  let page_id = document.get_page_id().unwrap();
  let block_ids = document.get_block_children_ids(&page_id);
  let mut page_ids = vec![];
  let mut link_ids = vec![];
  for block_id in block_ids.iter() {
    // Process block deltas
    if let Some(mut block_deltas) = document.get_block_delta(block_id).map(|t| t.1) {
      for d in block_deltas.iter_mut() {
        if let TextDelta::Inserted(_, Some(attrs)) = d {
          if let Some(Any::Map(mention)) = attrs.get_mut("mention") {
            if let Some(page_id) = mention.get("page_id").map(|v| v.to_string()) {
              page_ids.push(page_id);
            }
          }
        }
      }
    }

    if let Some((_, data)) = document.get_block_data(block_id) {
      if let Some(link_view_id) = data.get("view_id").and_then(|v| v.as_str()) {
        link_ids.push(link_view_id.to_string());
      }
    }
  }

  assert_eq!(page_ids.len(), 1);
  for page_id in page_ids {
    let view = test.get_view(&page_id).await;
    assert_eq!(view.name, "1");
    let data = serde_json::to_string(&test.get_document_data(&view.id).await).unwrap();
    assert!(data.contains("hello world"));
  }

  assert_eq!(link_ids.len(), 1);
  for link_id in link_ids {
    let database_view = test.get_view(&link_id).await;
    assert_eq!(database_view.layout, ViewLayoutPB::Grid);
    assert_eq!(database_view.name, "Untitled");
  }
}

#[tokio::test]
async fn import_appflowy_data_folder_into_new_view_test() {
  let import_container_name = "040_local".to_string();
  let (cleaner, user_db_path) = unzip("./tests/asset", &import_container_name).unwrap();
  // In the 040_local, the structure is:
  //  Document1
  //     Document2
  //       Grid1
  //       Grid2
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[0].name, "General");
  assert_eq!(views[1].name, "Shared");
  assert_eq!(views.len(), 2);
  let shared_space_id = views[1].id.clone();
  let shared_space = test.get_view(&shared_space_id).await;

  // by default, shared space is empty
  assert!(shared_space.child_views.is_empty());
  // after sign up, the initial workspace is created, so the structure is:
  // workspace:
  //   General
  //     template_document
  //     template_document
  //   Shared

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  // workspace:
  //   General
  //     template_document
  //     template_document
  //     040_local
  //   Shared
  let general_space = test.get_view(&shared_space_id).await;
  let shared_sub_views = &general_space.child_views;
  assert_eq!(shared_sub_views.len(), 1);
  assert_eq!(shared_sub_views[0].name, import_container_name);

  // the 040_local should be an empty document, so try to get the document data
  let _ = test.get_document_data(&shared_sub_views[0].id).await;

  let t_040_local_child_views = test.get_view(&shared_sub_views[0].id).await.child_views;
  assert_eq!(t_040_local_child_views[0].name, "Document1");

  let document1_child_views = test
    .get_view(&t_040_local_child_views[0].id)
    .await
    .child_views;
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
  //  Document1
  //     Document2
  //       Grid1
  //       Grid2
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  // after sign up, the initial workspace is created, so the structure is:
  // workspace:
  //   view: Getting Started

  test
    .import_appflowy_data(user_db_path.to_str().unwrap().to_string(), None)
    .await
    .unwrap();
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[0].name, "General");
  assert_eq!(views[1].name, "Shared");
  assert_eq!(views.len(), 2);
  let shared_space_id = views[1].id.clone();
  let shared_space_child_views = test.get_view(&shared_space_id).await.child_views;
  assert_eq!(shared_space_child_views.len(), 1);

  // after import, the structure is:
  // workspace:
  //   General
  //   Shared
  //      Document1
  //        Document2
  //           Grid1
  //           Grid2
  let document_1 = test.get_view(&shared_space_child_views[0].id).await;
  assert_eq!(document_1.name, "Document1");
  let document_1_child_views = test.get_view(&document_1.id).await.child_views;
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
async fn import_empty_appflowy_data_folder_test() {
  let path = temp_dir();
  use_localhost_af_cloud().await;
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
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  let _ = test.af_cloud_sign_up().await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[0].name, "General");
  assert_eq!(views[1].name, "Shared");
  assert_eq!(views.len(), 2);
  let shared_space_id = views[1].id.clone();
  let shared_space = test.get_view(&shared_space_id).await;
  // by default, shared space is empty
  assert!(shared_space.child_views.is_empty());

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  //   General
  //   Shared
  //      040_local_2
  //        Getting Started
  //           Doc1
  //           Doc2
  //           Grid1
  //           Doc3
  //              Doc3_grid_1
  //              Doc3_grid_2
  //              Doc3_calendar_1

  let shared_space_children_views = test.get_view(&shared_space_id).await.child_views;
  assert_eq!(shared_space_children_views.len(), 1);
  let _040_local_view_id = shared_space_children_views[0].id.clone();
  let _040_local_view = test.get_view(&_040_local_view_id).await;
  assert_eq!(_040_local_view.name, import_container_name);
  assert_040_local_2_import_content(&test, &_040_local_view_id).await;

  test
    .import_appflowy_data(
      user_db_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();
  // after import, the structure is:
  //   Generate
  //   Shared
  //     040_local_2
  //     040_local_2
  let shared_space_children_views = test.get_view(&shared_space_id).await.child_views;
  assert_eq!(shared_space_children_views.len(), 2);
  for view in shared_space_children_views {
    assert_040_local_2_import_content(&test, &view.id).await;
  }
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
