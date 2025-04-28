use crate::user_event::TestNotificationSender;
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_entity::CollabType;
use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::AppFlowyCore;
use flowy_notification::register_notification_sender;
use flowy_user::entities::AuthTypePB;
use flowy_user::errors::FlowyError;
use lib_dispatch::runtime::AFPluginRuntime;
use nanoid::nanoid;
use semver::Version;
use std::env::temp_dir;
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::atomic::{AtomicBool, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::select;
use tokio::task::LocalSet;
use tokio::time::sleep;
use uuid::Uuid;

mod chat_event;
pub mod database_event;
pub mod document;
pub mod document_event;
pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct EventIntegrationTest {
  pub authenticator: Arc<AtomicU8>,
  pub appflowy_core: AppFlowyCore,
  #[allow(dead_code)]
  cleaner: Arc<Cleaner>,
  pub notification_sender: TestNotificationSender,
  local_set: Arc<LocalSet>,
}

pub const SINGLE_FILE_UPLOAD_SIZE: usize = 15 * 1024 * 1024;

impl EventIntegrationTest {
  pub async fn new() -> Self {
    Self::new_with_name(nanoid!(6)).await
  }

  pub async fn new_with_name<T: ToString>(name: T) -> Self {
    let temp_dir = temp_dir().join(nanoid!(6));
    std::fs::create_dir_all(&temp_dir).unwrap();
    Self::new_with_user_data_path(temp_dir, name.to_string()).await
  }

  pub async fn new_with_config(config: AppFlowyCoreConfig) -> Self {
    let clean_path = config.storage_path.clone();
    let inner = init_core(config).await;
    let notification_sender = TestNotificationSender::new();
    let authenticator = Arc::new(AtomicU8::new(AuthTypePB::Local as u8));
    register_notification_sender(notification_sender.clone());

    // In case of dropping the runtime that runs the core, we need to forget the dispatcher
    std::mem::forget(inner.dispatcher());
    Self {
      appflowy_core: inner,
      authenticator,
      notification_sender,
      cleaner: Arc::new(Cleaner::new(PathBuf::from(clean_path))),
      #[allow(clippy::arc_with_non_send_sync)]
      local_set: Arc::new(Default::default()),
    }
  }

  pub async fn new_with_user_data_path(path_buf: PathBuf, name: String) -> Self {
    let path = path_buf.to_str().unwrap().to_string();
    let device_id = uuid::Uuid::new_v4().to_string();
    let mut config = AppFlowyCoreConfig::new(
      Version::new(0, 7, 0),
      path.clone(),
      path,
      device_id,
      "test".to_string(),
      name,
    )
    .log_filter(
      "trace",
      vec![
        "flowy_test".to_string(),
        "tokio".to_string(),
        // "lib_dispatch".to_string(),
      ],
    );

    if let Some(cloud_config) = config.cloud_config.as_mut() {
      cloud_config.maximum_upload_file_size_in_bytes = Some(SINGLE_FILE_UPLOAD_SIZE as u64);
    }
    Self::new_with_config(config).await
  }

  pub fn skip_auto_remove_temp_dir(&mut self) {
    self.cleaner.should_clean.store(false, Ordering::Release);
  }

  pub fn instance_name(&self) -> String {
    self.appflowy_core.config.name.clone()
  }

  pub fn user_data_path(&self) -> String {
    self.appflowy_core.config.application_path.clone()
  }

  pub async fn wait_ws_connected(&self) {
    if self
      .appflowy_core
      .server_provider
      .get_server()
      .unwrap()
      .get_ws_state()
      .is_connected()
    {
      return;
    }

    let mut ws_state = self
      .appflowy_core
      .server_provider
      .get_server()
      .unwrap()
      .subscribe_ws_state()
      .unwrap();
    loop {
      select! {
        _ = sleep(Duration::from_secs(20)) => {
          panic!("wait_ws_connected timeout");
        }
        state = ws_state.recv() => {
          if let Ok(state) = &state {
            if state.is_connected() {
              break;
            }
          }
        }
      }
    }
  }

  pub async fn get_collab_doc_state(
    &self,
    oid: &str,
    collab_type: CollabType,
  ) -> Result<Vec<u8>, FlowyError> {
    let server = self.server_provider.get_server()?;

    let workspace_id = self.get_current_workspace().await.id;
    let oid = Uuid::from_str(oid)?;
    let uid = self.get_user_profile().await?.id;
    let doc_state = server
      .folder_service()
      .get_folder_doc_state(
        &Uuid::from_str(&workspace_id).unwrap(),
        uid,
        collab_type,
        &oid,
      )
      .await?;

    Ok(doc_state)
  }
}

pub fn document_data_from_document_doc_state(doc_id: &str, doc_state: Vec<u8>) -> DocumentData {
  document_from_document_doc_state(doc_id, doc_state)
    .get_document_data()
    .unwrap()
}

pub fn document_from_document_doc_state(doc_id: &str, doc_state: Vec<u8>) -> Document {
  let collab = Collab::new_with_source(
    CollabOrigin::Empty,
    doc_id,
    DataSource::DocStateV1(doc_state),
    vec![],
    true,
  )
  .unwrap();
  Document::open(collab).unwrap()
}

async fn init_core(config: AppFlowyCoreConfig) -> AppFlowyCore {
  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  let cloned_runtime = runtime.clone();
  AppFlowyCore::new(config, cloned_runtime, None).await
}

impl std::ops::Deref for EventIntegrationTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.appflowy_core
  }
}

pub struct Cleaner {
  dir: PathBuf,
  should_clean: AtomicBool,
}

impl Cleaner {
  pub fn new(dir: PathBuf) -> Self {
    Self {
      dir,
      should_clean: AtomicBool::new(true),
    }
  }

  fn cleanup(dir: &PathBuf) {
    let _ = std::fs::remove_dir_all(dir);
  }
}

impl Drop for Cleaner {
  fn drop(&mut self) {
    if self.should_clean.load(Ordering::Acquire) {
      Self::cleanup(&self.dir)
    }
  }
}
