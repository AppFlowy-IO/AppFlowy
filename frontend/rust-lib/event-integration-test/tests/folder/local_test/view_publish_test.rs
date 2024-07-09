use collab_folder::ViewLayout;
use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::{ViewLayoutPB, ViewPB};
use flowy_folder::publish_util::generate_publish_name;
use flowy_folder_pub::entities::{
  PublishViewInfo, PublishViewMeta, PublishViewMetaData, PublishViewPayload,
};

async fn mock_single_document_view_publish_payload(
  test: &EventIntegrationTest,
  view: &ViewPB,
  publish_name: String,
) -> Vec<PublishViewPayload> {
  let view_id = &view.id;
  let layout: ViewLayout = view.layout.clone().into();
  let view_encoded_collab = test.encoded_collab_v1(view_id, layout).await;
  let publish_view_info = PublishViewInfo {
    view_id: view_id.to_string(),
    name: view.name.to_string(),
    icon: None,
    layout: ViewLayout::Document,
    extra: None,
    created_by: view.created_by,
    last_edited_by: view.last_edited_by,
    last_edited_time: view.last_edited,
    created_at: view.create_time,
    child_views: None,
  };

  vec![PublishViewPayload {
    meta: PublishViewMeta {
      metadata: PublishViewMetaData {
        view: publish_view_info.clone(),
        child_views: vec![],
        ancestor_views: vec![publish_view_info],
      },
      view_id: view_id.to_string(),
      publish_name,
    },
    data: Vec::from(view_encoded_collab.doc_state),
  }]
}

async fn mock_nested_document_view_publish_payload(
  test: &EventIntegrationTest,
  view: &ViewPB,
  publish_name: String,
) -> Vec<PublishViewPayload> {
  let view_id = &view.id;
  let layout: ViewLayout = view.layout.clone().into();
  let view_encoded_collab = test.encoded_collab_v1(view_id, layout).await;
  let publish_view_info = PublishViewInfo {
    view_id: view_id.to_string(),
    name: view.name.to_string(),
    icon: None,
    layout: ViewLayout::Document,
    extra: None,
    created_by: view.created_by,
    last_edited_by: view.last_edited_by,
    last_edited_time: view.last_edited,
    created_at: view.create_time,
    child_views: None,
  };

  let child_view_id = &view.child_views[0].id;
  let child_view = test.get_view(child_view_id).await;
  let child_layout: ViewLayout = child_view.layout.clone().into();
  let child_view_encoded_collab = test.encoded_collab_v1(child_view_id, child_layout).await;
  let child_publish_view_info = PublishViewInfo {
    view_id: child_view_id.to_string(),
    name: child_view.name.to_string(),
    icon: None,
    layout: ViewLayout::Document,
    extra: None,
    created_by: child_view.created_by,
    last_edited_by: child_view.last_edited_by,
    last_edited_time: child_view.last_edited,
    created_at: child_view.create_time,
    child_views: None,
  };
  let child_publish_name = generate_publish_name(&child_view.id, &child_view.name);

  vec![
    PublishViewPayload {
      meta: PublishViewMeta {
        metadata: PublishViewMetaData {
          view: publish_view_info.clone(),
          child_views: vec![child_publish_view_info.clone()],
          ancestor_views: vec![publish_view_info.clone()],
        },
        view_id: view_id.to_string(),
        publish_name,
      },
      data: Vec::from(view_encoded_collab.doc_state),
    },
    PublishViewPayload {
      meta: PublishViewMeta {
        metadata: PublishViewMetaData {
          view: child_publish_view_info.clone(),
          child_views: vec![],
          ancestor_views: vec![publish_view_info.clone(), child_publish_view_info.clone()],
        },
        view_id: child_view_id.to_string(),
        publish_name: child_publish_name,
      },
      data: Vec::from(child_view_encoded_collab.doc_state),
    },
  ]
}

async fn create_single_document(test: &EventIntegrationTest, view_id: &str, name: &str) {
  test
    .create_orphan_view(name, view_id, ViewLayoutPB::Document)
    .await;
}

async fn create_nested_document(test: &EventIntegrationTest, view_id: &str, name: &str) {
  create_single_document(test, view_id, name).await;
  let child_name = "Child View";
  test.create_view(view_id, child_name.to_string()).await;
}
#[tokio::test]
async fn single_document_get_publish_view_payload_test() {
  let test = EventIntegrationTest::new_anon().await;
  let view_id = "20240521";
  let name = "Orphan View";
  create_single_document(&test, view_id, name).await;
  let view = test.get_view(view_id).await;
  let payload = test.get_publish_payload(view_id, true).await;

  let expect_payload = mock_single_document_view_publish_payload(
    &test,
    &view,
    format!("{}-{}", "Orphan-View", view_id),
  )
  .await;

  assert_eq!(payload, expect_payload);
}

#[tokio::test]
async fn nested_document_get_publish_view_payload_test() {
  let test = EventIntegrationTest::new_anon().await;
  let name = "Orphan View";
  let view_id = "20240521";
  create_nested_document(&test, view_id, name).await;
  let view = test.get_view(view_id).await;
  let payload = test.get_publish_payload(view_id, true).await;

  let expect_payload = mock_nested_document_view_publish_payload(
    &test,
    &view,
    format!("{}-{}", "Orphan-View", view_id),
  )
  .await;

  assert_eq!(payload.len(), 2);
  assert_eq!(payload, expect_payload);
}

#[tokio::test]
async fn no_children_publish_view_payload_test() {
  let test = EventIntegrationTest::new_anon().await;
  let name = "Orphan View";
  let view_id = "20240521";
  create_nested_document(&test, view_id, name).await;
  let view = test.get_view(view_id).await;
  let payload = test.get_publish_payload(view_id, false).await;

  let data = mock_single_document_view_publish_payload(
    &test,
    &view,
    format!("{}-{}", "Orphan-View", view_id),
  )
  .await
  .iter()
  .map(|p| p.data.clone())
  .collect::<Vec<_>>();
  let meta = mock_nested_document_view_publish_payload(
    &test,
    &view,
    format!("{}-{}", "Orphan-View", view_id),
  )
  .await
  .iter()
  .map(|p| p.meta.clone())
  .collect::<Vec<_>>();

  assert_eq!(payload.len(), 1);
  assert_eq!(&payload[0].data, &data[0]);
  assert_eq!(&payload[0].meta, &meta[0]);
}
