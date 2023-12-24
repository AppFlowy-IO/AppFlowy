use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_user::entities::AuthenticatorPB;

use crate::util::unzip_history_user_db;

#[tokio::test]
async fn reading_039_anon_user_data_test() {
  let (cleaner, user_db_path) = unzip_history_user_db("./tests/asset", "039_local").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let first_level_views = test.get_all_workspace_views().await;
  // In the 039_local, the structure is:
  // workspace:
  //  view: Document1
  //    view: Document2
  //      view: Grid1
  //      view: Grid2
  assert_eq!(first_level_views.len(), 1);
  assert_eq!(
    first_level_views[0].id,
    "50a150e0-2aa9-4131-a259-8ef989315540".to_string()
  );
  assert_eq!(first_level_views[0].name, "Document1".to_string());

  let second_level_views = test.get_views(&first_level_views[0].id).await.child_views;
  assert_eq!(second_level_views.len(), 1);
  assert_eq!(second_level_views[0].name, "Document2".to_string());

  // In the 039_local, there is only one view of the workspaces child
  let third_level_views = test.get_views(&second_level_views[0].id).await.child_views;
  assert_eq!(third_level_views.len(), 2);
  assert_eq!(third_level_views[0].name, "Grid1".to_string());
  assert_eq!(third_level_views[1].name, "Grid2".to_string());

  drop(cleaner);
}
#[tokio::test]
async fn anon_user_to_af_cloud_test() {
  let (cleaner, user_db_path) = unzip_history_user_db("./tests/asset", "039_local").unwrap();
  user_localhost_af_cloud().await;
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let anon_first_level_views = test.get_all_workspace_views().await;
  let _anon_second_level_views = test
    .get_views(&anon_first_level_views[0].id)
    .await
    .child_views;

  let user = test.af_cloud_sign_up().await;
  assert_eq!(user.authenticator, AuthenticatorPB::AppFlowyCloud);
  // let mut sync_state = test
  //   .folder_manager
  //   .get_mutex_folder()
  //   .lock()
  //   .as_ref()
  //   .unwrap()
  //   .subscribe_sync_state();
  //
  // // TODO(nathan): will be removed when supporting merge FolderData
  // // wait until the state is SyncFinished with 10 secs timeout
  // loop {
  //   select! {
  //     _ = tokio::time::sleep(Duration::from_secs(10)) => {
  //       panic!("Timeout waiting for sync finished");
  //     }
  //     state = sync_state.next() => {
  //       if let Some(state) = &state {
  //         if state == &SyncState::SyncFinished {
  //           break;
  //         }
  //       }
  //     }
  //   }
  // }
  //
  // let user_first_level_views = test.get_all_workspace_views().await;
  // let user_second_level_views = test
  //   .get_views(&user_first_level_views[1].id)
  //   .await
  //   .child_views;
  //
  // // first
  // assert_eq!(anon_first_level_views.len(), 1);
  // assert_eq!(user_first_level_views.len(), 2);
  // assert_eq!(
  //   anon_first_level_views[0].name,
  //   // The first one is the get started document
  //   user_first_level_views[1].name
  // );
  // assert_ne!(anon_first_level_views[0].id, user_first_level_views[1].id);
  //
  // // second
  // assert_eq!(anon_second_level_views.len(), user_second_level_views.len());
  // assert_eq!(
  //   anon_second_level_views[0].name,
  //   user_second_level_views[0].name
  // );
  // assert_ne!(anon_second_level_views[0].id, user_second_level_views[0].id);
  drop(cleaner);
}
