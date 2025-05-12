use crate::util::load_text_file_content;
use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_user_pub::entities::WorkspaceType;

#[tokio::test]
async fn local_ollama_test_create_chat_with_selected_sources() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  test.toggle_local_ai().await;

  let local_workspace = test
    .create_workspace("my workspace", WorkspaceType::Local)
    .await;

  // create a chat document
  test
    .open_workspace(
      &local_workspace.workspace_id,
      local_workspace.workspace_type,
    )
    .await;
  let doc = test
    .create_and_open_document(
      &local_workspace.workspace_id,
      "japan trip".to_string(),
      vec![],
    )
    .await;
  let content = load_text_file_content("japan_trip.md");
  test.insert_document_text(&doc.id, &content, 0).await;

  //chat with the document
  let chat = test.create_chat(&local_workspace.workspace_id).await;
  test
    .set_chat_rag_ids(&chat.id, vec![doc.id.to_string()])
    .await;

  // test
  //   .send_message(&chat.id, "why use rust?", ChatMessageTypePB::User)
  //   .await;
}
