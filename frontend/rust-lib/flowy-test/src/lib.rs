use std::env::temp_dir;
use std::sync::Arc;

use nanoid::nanoid;
use parking_lot::RwLock;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_database2::entities::*;
use flowy_folder2::entities::*;
use flowy_user::entities::{AuthTypePB, UserProfilePB};
use flowy_user::errors::FlowyError;

use crate::event_builder::EventBuilder;
use crate::user_event::{async_sign_up, init_user_setting, SignUpContext};

pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct FlowyCoreTest {
  auth_type: Arc<RwLock<AuthTypePB>>,
  inner: AppFlowyCore,
}

impl Default for FlowyCoreTest {
  fn default() -> Self {
    let temp_dir = temp_dir();
    let config =
      AppFlowyCoreConfig::new(temp_dir.to_str().unwrap(), nanoid!(6)).log_filter("info", vec![]);
    let inner = std::thread::spawn(|| AppFlowyCore::new(config))
      .join()
      .unwrap();
    let auth_type = Arc::new(RwLock::new(AuthTypePB::Local));
    std::mem::forget(inner.dispatcher());
    Self { inner, auth_type }
  }
}

impl FlowyCoreTest {
  pub fn new() -> Self {
    Self::default()
  }

  pub async fn new_with_user() -> Self {
    let test = Self::default();
    test.sign_up().await;
    test
  }

  pub async fn sign_up(&self) -> SignUpContext {
    let auth_type = self.auth_type.read().clone();
    async_sign_up(self.inner.dispatcher(), auth_type).await
  }

  pub fn set_auth_type(&self, auth_type: AuthTypePB) {
    *self.auth_type.write() = auth_type;
  }

  pub async fn init_user(&self) -> UserProfilePB {
    let auth_type = self.auth_type.read().clone();
    let context = async_sign_up(self.inner.dispatcher(), auth_type).await;
    init_user_setting(self.inner.dispatcher()).await;
    context.user_profile
  }

  pub async fn get_current_workspace(&self) -> WorkspaceSettingPB {
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::GetCurrentWorkspace)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::WorkspaceSettingPB>()
  }

  pub async fn get_all_workspace_views(&self) -> Vec<ViewPB> {
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::ReadWorkspaceViews)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::RepeatedViewPB>()
      .items
  }

  pub async fn delete_view(&self, view_id: &str) {
    let payload = RepeatedViewIdPB {
      items: vec![view_id.to_string()],
    };

    // delete the view. the view will be moved to trash
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::DeleteView)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn create_view(&self, parent_id: &str, name: String) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: Default::default(),
      initial_data: vec![],
      meta: Default::default(),
      set_as_current: false,
    };
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn create_grid(&self, parent_id: &str, name: String, initial_data: Vec<u8>) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Grid,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
    };
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn get_database(&self, view_id: &str) -> DatabasePB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::GetDatabase)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<flowy_database2::entities::DatabasePB>()
  }

  pub async fn get_all_database_fields(&self, view_id: &str) -> RepeatedFieldPB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::GetFields)
      .payload(GetFieldPayloadPB {
        view_id: view_id.to_string(),
        field_ids: None,
      })
      .async_send()
      .await
      .parse::<RepeatedFieldPB>()
  }

  pub async fn create_field(&self, view_id: &str, field_type: FieldType) -> FieldPB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::CreateTypeOption)
      .payload(CreateFieldPayloadPB {
        view_id: view_id.to_string(),
        field_type,
        type_option_data: None,
      })
      .async_send()
      .await
      .parse::<TypeOptionPB>()
      .field
  }

  pub async fn update_field(&self, changeset: FieldChangesetPB) {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::UpdateField)
      .payload(changeset)
      .async_send()
      .await;
  }

  pub async fn delete_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::DeleteField)
      .payload(DeleteFieldPayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_field_type(
    &self,
    view_id: &str,
    field_id: &str,
    field_type: FieldType,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::UpdateFieldType)
      .payload(UpdateFieldTypePayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
        field_type,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn duplicate_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::DuplicateField)
      .payload(DuplicateFieldPayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn create_row(
    &self,
    view_id: &str,
    start_row_id: Option<String>,
    data: Option<RowDataPB>,
  ) -> RowPB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::CreateRow)
      .payload(CreateRowPayloadPB {
        view_id: view_id.to_string(),
        start_row_id,
        group_id: None,
        data,
      })
      .async_send()
      .await
      .parse::<RowPB>()
  }

  pub async fn get_row(&self, view_id: &str, row_id: &str) -> RowPB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::GetRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .parse::<RowPB>()
  }

  pub async fn duplicate_row(&self, view_id: &str, row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::DuplicateRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_cell(&self, changeset: CellChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::UpdateCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> CellPB {
    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::GetCell)
      .payload(CellIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .parse::<CellPB>()
  }

  pub async fn insert_option(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
    name: &str,
  ) -> Option<FlowyError> {
    let option = EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::CreateSelectOption)
      .payload(CreateSelectOptionPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
        option_name: name.to_string(),
      })
      .async_send()
      .await
      .parse::<SelectOptionPB>();

    EventBuilder::new(self.clone())
      .event(flowy_database2::event_map::DatabaseEvent::InsertOrUpdateSelectOption)
      .payload(RepeatedSelectOptionPayload {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
        row_id: row_id.to_string(),
        items: vec![option],
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_view(&self, view_id: &str) -> ViewPB {
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::ReadView)
      .payload(ViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }
}

impl std::ops::Deref for FlowyCoreTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

// pub struct TestNotificationSender {
//   pub(crate) sender: tokio::sync::mpsc::Sender<()>,
// }
//
// impl NotificationSender for TestNotificationSender {
//   fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
//     todo!()
//   }
// }
