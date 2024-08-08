use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_entity::CollabType;
use std::env::temp_dir;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::Arc;
use std::time::Duration;

use nanoid::nanoid;
use semver::Version;
use tokio::select;
use tokio::time::sleep;

use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::AppFlowyCore;
use flowy_notification::register_notification_sender;
use flowy_server::AppFlowyServer;
use flowy_user::entities::AuthenticatorPB;
use flowy_user::errors::FlowyError;
use lib_dispatch::runtime::AFPluginRuntime;

use crate::user_event::TestNotificationSender;

mod chat_event;
pub mod database_event;
pub mod document;
pub mod document_event;
pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct EventIntegrationTest {
  pub authenticator: Arc<RwLock<AuthenticatorPB>>,
  pub appflowy_core: AppFlowyCore,
  #[allow(dead_code)]
  cleaner: Arc<Mutex<Cleaner>>,
  pub notification_sender: TestNotificationSender,
}

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
    let authenticator = Arc::new(RwLock::new(AuthenticatorPB::Local));
    register_notification_sender(notification_sender.clone());

    // In case of dropping the runtime that runs the core, we need to forget the dispatcher
    std::mem::forget(inner.dispatcher());
    Self {
      appflowy_core: inner,
      authenticator,
      notification_sender,
      cleaner: Arc::new(Mutex::new(Cleaner::new(PathBuf::from(clean_path)))),
    }
  }

  pub async fn new_with_user_data_path(path_buf: PathBuf, name: String) -> Self {
    let path = path_buf.to_str().unwrap().to_string();
    let device_id = uuid::Uuid::new_v4().to_string();
    let config = AppFlowyCoreConfig::new(
      Version::new(0, 5, 8),
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
    Self::new_with_config(config).await
  }

  pub fn skip_clean(&mut self) {
    self.cleaner.lock().should_clean = false;
  }

  pub fn instance_name(&self) -> String {
    self.appflowy_core.config.name.clone()
  }

  pub fn user_data_path(&self) -> String {
    self.appflowy_core.config.application_path.clone()
  }

  pub fn get_server(&self) -> Arc<dyn AppFlowyServer> {
    self.appflowy_core.server_provider.get_server().unwrap()
  }

  pub async fn wait_ws_connected(&self) {
    if self.get_server().get_ws_state().is_connected() {
      return;
    }

    let mut ws_state = self.get_server().subscribe_ws_state().unwrap();
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
    let server = self.server_provider.get_server().unwrap();
    let workspace_id = self.get_current_workspace().await.id;
    let uid = self.get_user_profile().await?.id;
    let doc_state = server
      .folder_service()
      .get_folder_doc_state(&workspace_id, uid, collab_type, oid)
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
  Document::from_doc_state(
    CollabOrigin::Empty,
    DataSource::DocStateV1(doc_state),
    doc_id,
    vec![],
  )
  .unwrap()
}

async fn init_core(config: AppFlowyCoreConfig) -> AppFlowyCore {
  let runtime = Rc::new(AFPluginRuntime::new().unwrap());
  let cloned_runtime = runtime.clone();
  AppFlowyCore::new(config, cloned_runtime, None).await
}

impl std::ops::Deref for EventIntegrationTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.appflowy_core
  }
}

#[derive(Clone)]
pub struct Cleaner {
  dir: PathBuf,
  should_clean: bool,
}

impl Cleaner {
  pub fn new(dir: PathBuf) -> Self {
    Self {
      dir,
      should_clean: true,
    }
  }

  fn cleanup(dir: &PathBuf) {
    let _ = std::fs::remove_dir_all(dir);
  }
}

impl Drop for Cleaner {
  fn drop(&mut self) {
    if self.should_clean {
      Self::cleanup(&self.dir)
    }
  }
}
