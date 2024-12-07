use crate::util::{receive_with_timeout, unzip};
use collab_document::blocks::DocumentData;
use collab_folder::SpaceInfo;
use event_integration_test::document_event::assert_document_data_equal;
use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_document::entities::{DocumentSyncState, DocumentSyncStatePB};
use serde_json::json;
use std::time::Duration;

#[tokio::test]
async fn af_cloud_edit_document_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  test.wait_ws_connected().await;

  // create document and then insert content
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_and_open_document(&current_workspace.id, "my document".to_string(), vec![])
    .await;
  test.insert_document_text(&view.id, "hello world", 0).await;

  let document_id = view.id;
  println!("document_id: {}", document_id);

  // wait all update are send to the remote
  let rx = test
    .notification_sender
    .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| {
      pb.value == DocumentSyncState::SyncFinished
    });
  let _ = receive_with_timeout(rx, Duration::from_secs(30)).await;

  let document_data = test.get_document_data(&document_id).await;
  let doc_state = test.get_document_doc_state(&document_id).await;
  assert!(!doc_state.is_empty());
  assert_document_data_equal(&doc_state, &document_id, document_data);
}

#[tokio::test]
async fn af_cloud_sync_anon_user_document_test() {
  let user_db_path = unzip("./tests/asset", "040_sync_local_document").unwrap();
  use_localhost_af_cloud().await;
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path.clone(), DEFAULT_NAME.to_string())
      .await;
  test.af_cloud_sign_up().await;
  test.wait_ws_connected().await;

  // In the 040_sync_local_document, the structure is:
  // workspace:
  //  view: SyncDocument
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  for view in views.iter() {
    let space_info = serde_json::from_str::<SpaceInfo>(view.extra.as_ref().unwrap()).unwrap();
    assert!(space_info.is_space);
  }

  let document_id = views[2].id.clone();
  test.open_document(document_id.clone()).await;

  // wait all update are send to the remote
  let rx = test
    .notification_sender
    .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| {
      pb.value != DocumentSyncState::Syncing
    });
  let _ = receive_with_timeout(rx, Duration::from_secs(30)).await;

  let doc_state = test.get_document_doc_state(&document_id).await;
  assert_document_data_equal(
    &doc_state,
    &document_id,
    expected_040_sync_local_document_data(),
  );
}

fn expected_040_sync_local_document_data() -> DocumentData {
  serde_json::from_value(json!( {
    "blocks": {
      "2hYJqg": {
        "children": "AdDT7G",
        "data": {
          "delta": [
            {
              "insert": "bullet list format"
            }
          ]
        },
        "external_id": null,
        "external_type": null,
        "id": "2hYJqg",
        "parent": "beEtQt9xw6",
        "ty": "bulleted_list"
      },
      "9GWi-3": {
        "children": "osttqJ",
        "data": {
          "delta": [
            {
              "insert": "quote format"
            }
          ]
        },
        "external_id": null,
        "external_type": null,
        "id": "9GWi-3",
        "parent": "beEtQt9xw6",
        "ty": "quote"
      },
      "RB-9fj": {
        "children": "GNv1Bx",
        "data": {
          "delta": [
            {
              "insert": "number list format"
            }
          ]
        },
        "external_id": null,
        "external_type": null,
        "id": "RB-9fj",
        "parent": "beEtQt9xw6",
        "ty": "numbered_list"
      },
      "TtoXrhXQKK": {
        "children": "xVai4jK835",
        "data": {
          "delta": [
            {
              "insert": "Syncing the document content between server and the local."
            }
          ]
        },
        "external_id": "-qBAb5hSHZ",
        "external_type": "text",
        "id": "TtoXrhXQKK",
        "parent": "beEtQt9xw6",
        "ty": "paragraph"
      },
      "beEtQt9xw6": {
        "children": "e8O8NqDFSa",
        "data": {},
        "external_id": null,
        "external_type": null,
        "id": "beEtQt9xw6",
        "parent": "",
        "ty": "page"
      },
      "m59P6g": {
        "children": "x2Nypz",
        "data": {
          "delta": [
            {
              "insert": "Header one format"
            }
          ],
          "level": 1
        },
        "external_id": null,
        "external_type": null,
        "id": "m59P6g",
        "parent": "beEtQt9xw6",
        "ty": "heading"
      },
      "mvGqkR": {
        "children": "k7Pozf",
        "data": {
          "delta": [
            {
              "insert": "Header two format"
            }
          ],
          "level": 2
        },
        "external_id": null,
        "external_type": null,
        "id": "mvGqkR",
        "parent": "beEtQt9xw6",
        "ty": "heading"
      },
      "otbxLc": {
        "children": "QJGGOs",
        "data": {
          "checked": false,
          "delta": [
            {
              "insert": "checkbox format"
            }
          ]
        },
        "external_id": null,
        "external_type": null,
        "id": "otbxLc",
        "parent": "beEtQt9xw6",
        "ty": "todo_list"
      },
      "qOb8PS": {
        "children": "fbEQ-2",
        "data": {
          "delta": [
            {
              "insert": "It contains lots of formats."
            }
          ]
        },
        "external_id": null,
        "external_type": null,
        "id": "qOb8PS",
        "parent": "beEtQt9xw6",
        "ty": "paragraph"
      }
    },
    "meta": {
      "children_map": {
        "AdDT7G": [],
        "GNv1Bx": [],
        "QJGGOs": [],
        "e8O8NqDFSa": [
          "TtoXrhXQKK",
          "qOb8PS",
          "m59P6g",
          "mvGqkR",
          "RB-9fj",
          "2hYJqg",
          "otbxLc",
          "9GWi-3"
        ],
        "fbEQ-2": [],
        "k7Pozf": [],
        "osttqJ": [],
        "x2Nypz": [],
        "xVai4jK835": []
      },
      "text_map": {
        "-qBAb5hSHZ": "[{\"insert\":\"Syncing the document content between server and the local.\"}]",
        "0qTSZK": "[]",
        "1aO3pe": "[]",
        "5PVbjJ": "[{\"insert\":\"It contains lots of formats.\"}]",
        "6Up-3y": "[]",
        "GkpKE6": "[{\"insert\":\"number list format\"}]",
        "Mhpd_J": "[{\"insert\":\"Header one format\"}]",
        "OvsPP4": "[]",
        "Ozaw6E": "[]",
        "Q2lcja": "[]",
        "YrAL0L": "[{\"insert\":\"Header two format\"}]",
        "cQHJvj": "[]",
        "eiHaS2": "[]",
        "hHGl05": "[{\"insert\":\"quote format\"}]",
        "ht7dE4": "[{\"insert\":\"bullet list format\"}]",
        "iWrg77": "[{\"insert\":\"checkbox format\"}]",
        "xSTRAY": "[]"
      }
    },
    "page_id": "beEtQt9xw6"
  })).unwrap()
}
