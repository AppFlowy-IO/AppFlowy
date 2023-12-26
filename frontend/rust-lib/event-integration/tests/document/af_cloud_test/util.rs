use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use std::ops::Deref;

#[derive(Clone)]
pub struct AFCloudDocumentTest {
  inner: EventIntegrationTest,
}

impl AFCloudDocumentTest {
  pub async fn new() -> Self {
    user_localhost_af_cloud().await;
    let inner = EventIntegrationTest::new().await;
    inner.af_cloud_sign_up().await;
    Self { inner }
  }

  // pub async fn create_document(&self) -> String {
  //   let current_workspace = self.inner.get_current_workspace().await;
  //   let view = self
  //     .inner
  //     .create_document(&current_workspace.id, "my document".to_string(), vec![])
  //     .await;
  //   tokio::time::sleep(Duration::from_secs(2)).await;
  //   view.id
  // }
}

impl Deref for AFCloudDocumentTest {
  type Target = EventIntegrationTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
