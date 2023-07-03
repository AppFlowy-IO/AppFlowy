use std::ops::Deref;

use flowy_database2::entities::{
  DatabaseExportDataPB, DatabasePB, DatabaseSnapshotPB, DatabaseViewIdPB,
  RepeatedDatabaseSnapshotPB,
};
use flowy_database2::event_map::DatabaseEvent::*;
use flowy_folder2::entities::ViewPB;
use flowy_test::event_builder::EventBuilder;

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

  pub async fn create_database(&self) -> (ViewPB, DatabasePB) {
    let current_workspace = self.inner.get_current_workspace().await;
    let view = self
      .inner
      .create_grid(
        &current_workspace.workspace.id,
        "my database".to_string(),
        vec![],
      )
      .await;
    let database = self.inner.get_database(&view.id).await;
    (view, database)
  }

  pub async fn export_csv(&self, database_id: &str) -> String {
    EventBuilder::new(self.inner.deref().clone())
      .event(ExportCSV)
      .payload(DatabaseViewIdPB {
        value: database_id.to_string(),
      })
      .async_send()
      .await
      .parse::<DatabaseExportDataPB>()
      .data
  }

  pub async fn get_database_snapshots(&self, view_id: &str) -> RepeatedDatabaseSnapshotPB {
    EventBuilder::new(self.inner.deref().clone())
      .event(GetDatabaseSnapshots)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedDatabaseSnapshotPB>()
  }
}

impl Deref for FlowySupabaseDatabaseTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
