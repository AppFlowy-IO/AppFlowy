use collab_folder::ViewLayout;
use event_integration::{folder_event::ViewTest, EventIntegrationTest};

pub struct SearchManagerTest {
  pub sdk: EventIntegrationTest,
  pub view_id: String,
}

impl SearchManagerTest {
  pub async fn new(sdk: EventIntegrationTest) -> Self {
    let view_test = ViewTest::new(&sdk, ViewLayout::Document, vec![]).await;
    let view_id = view_test.child_view.id;

    Self { sdk, view_id }
  }

  pub async fn new_folder_test() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;

    Self::new(sdk).await
  }
}
