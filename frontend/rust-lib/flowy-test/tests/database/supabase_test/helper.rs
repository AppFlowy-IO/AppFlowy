use flowy_database2::entities::DatabasePB;
use flowy_folder2::entities::ViewPB;

use crate::util::FlowySupabaseTest;

pub struct FlowySupabaseDatabaseTest {
  inner: FlowySupabaseTest,
}

impl FlowySupabaseDatabaseTest {
  pub async fn new() -> Option<Self> {
    let inner = FlowySupabaseTest::new()?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.sign_up_with_uuid(&uuid).await;
    Some(Self { inner })
  }

  pub async fn create_database(&self) -> DatabasePB {
    let current_workspace = self.inner.get_current_workspace().await;
    let view = self
      .inner
      .create_grid(
        &current_workspace.workspace.id,
        "my database".to_string(),
        vec![],
      )
      .await;
    self.inner.get_database(&view.id).await
  }
}
