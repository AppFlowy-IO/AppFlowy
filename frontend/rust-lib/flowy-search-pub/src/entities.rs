use std::sync::Arc;

use collab::core::collab::IndexContentReceiver;
use collab_folder::{View, ViewIcon, ViewLayout};
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub struct ViewObserveData {
  pub id: String,
  pub data: String,
  pub icon: Option<ViewIcon>,
  pub layout: ViewLayout,
  pub workspace_id: Uuid,
}

impl ViewObserveData {
  pub fn from_view(view: Arc<View>, workspace_id: Uuid) -> Self {
    ViewObserveData {
      id: view.id.clone(),
      data: view.name.clone(),
      icon: view.icon.clone(),
      layout: view.layout.clone(),
      workspace_id,
    }
  }
}

#[async_trait]
pub trait FolderViewObserver: Send + Sync {
  async fn set_observer_rx(&self, rx: IndexContentReceiver);
}

#[derive(Default, Debug, Clone)]
pub struct TanvitySearchResponseItem {
  pub id: String,
  pub display_name: String,
  pub icon: Option<ResultIcon>,
  pub workspace_id: String,
  pub content: String,
}

#[derive(Default, Debug, Clone, PartialEq, Eq)]
pub struct ResultIcon {
  pub ty: u8,
  pub value: String,
}
