use std::collections::HashMap;
use std::convert::TryFrom;
use std::env::temp_dir;
use std::path::PathBuf;
use std::sync::Arc;

use bytes::Bytes;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::{merge_updates_v1, Update};
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use nanoid::nanoid;
use parking_lot::RwLock;
use protobuf::ProtobufError;
use tokio::sync::broadcast::{channel, Sender};
use uuid::Uuid;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_database2::entities::*;
use flowy_database2::event_map::DatabaseEvent;
use flowy_document2::entities::{DocumentDataPB, OpenDocumentPayloadPB};
use flowy_document2::event_map::DocumentEvent;
use flowy_folder2::entities::icon::UpdateViewIconPayloadPB;
use flowy_folder2::entities::*;
use flowy_folder2::event_map::FolderEvent;
use flowy_notification::entities::SubscribeObject;
use flowy_notification::{register_notification_sender, NotificationSender};
use flowy_server::supabase::define::{USER_DEVICE_ID, USER_EMAIL, USER_SIGN_IN_URL, USER_UUID};
use flowy_user::entities::{
  AuthTypePB, OauthSignInPB, SignInUrlPB, SignInUrlPayloadPB, UpdateCloudConfigPB,
  UserCloudConfigPB, UserProfilePB,
};
use flowy_user::errors::{FlowyError, FlowyResult};
use flowy_user::event_map::UserEvent::*;

use crate::document::document_event::{DocumentEventTest, OpenDocumentData};
use crate::event_builder::EventBuilder;
use crate::user_event::{async_sign_up, SignUpContext};

pub mod document;
pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct FlowyCoreTest {
  auth_type: Arc<RwLock<AuthTypePB>>,
  inner: AppFlowyCore,
  #[allow(dead_code)]
  cleaner: Arc<Cleaner>,
  pub notification_sender: TestNotificationSender,
}

impl Default for FlowyCoreTest {
  fn default() -> Self {
    let temp_dir = temp_dir().join(nanoid!(6));
    std::fs::create_dir_all(&temp_dir).unwrap();
    Self::new_with_user_data_path(temp_dir, nanoid!(6))
  }
}

impl FlowyCoreTest {
  pub fn new() -> Self {
    Self::default()
  }

  pub async fn insert_document_text(&self, document_id: &str, text: &str, index: usize) {
    let document_event = DocumentEventTest::new_with_core(self.clone());
    document_event
      .insert_index(document_id, text, index, None)
      .await;
  }

  pub async fn get_document_data(&self, view_id: &str) -> DocumentData {
    let pb = EventBuilder::new(self.clone())
      .event(DocumentEvent::GetDocumentData)
      .payload(OpenDocumentPayloadPB {
        document_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<DocumentDataPB>();

    DocumentData::from(pb)
  }

  pub async fn get_document_update(&self, document_id: &str) -> Vec<u8> {
    let cloud_service = self.document_manager.get_cloud_service().clone();
    let remote_updates = cloud_service
      .get_document_updates(document_id)
      .await
      .unwrap();

    if remote_updates.is_empty() {
      return vec![];
    }

    let updates = remote_updates
      .iter()
      .map(|update| update.as_ref())
      .collect::<Vec<&[u8]>>();

    merge_updates_v1(&updates).unwrap()
  }

  pub fn new_with_user_data_path(path: PathBuf, name: String) -> Self {
    let config = AppFlowyCoreConfig::new(path.to_str().unwrap(), name).log_filter(
      "trace",
      vec![
        "flowy_test".to_string(),
        // "lib_dispatch".to_string()
      ],
    );

    let inner = std::thread::spawn(|| AppFlowyCore::new(config))
      .join()
      .unwrap();
    let notification_sender = TestNotificationSender::new();
    let auth_type = Arc::new(RwLock::new(AuthTypePB::Local));
    register_notification_sender(notification_sender.clone());
    std::mem::forget(inner.dispatcher());
    Self {
      inner,
      auth_type,
      notification_sender,
      cleaner: Arc::new(Cleaner(path)),
    }
  }

  pub async fn enable_encryption(&self) -> String {
    let config = EventBuilder::new(self.clone())
      .event(GetCloudConfig)
      .async_send()
      .await
      .parse::<UserCloudConfigPB>();
    let update = UpdateCloudConfigPB {
      enable_sync: None,
      enable_encrypt: Some(true),
    };
    let error = EventBuilder::new(self.clone())
      .event(SetCloudConfig)
      .payload(update)
      .async_send()
      .await
      .error();
    assert!(error.is_none());
    config.encrypt_secret
  }

  pub async fn get_user_profile(&self) -> Result<UserProfilePB, FlowyError> {
    EventBuilder::new(self.clone())
      .event(GetUserProfile)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()
  }

  pub async fn new_with_guest_user() -> Self {
    let test = Self::default();
    test.sign_up_as_guest().await;
    test
  }

  pub async fn sign_up_as_guest(&self) -> SignUpContext {
    async_sign_up(self.inner.dispatcher(), AuthTypePB::Local).await
  }

  pub async fn supabase_party_sign_up(&self) -> UserProfilePB {
    let map = third_party_sign_up_param(Uuid::new_v4().to_string());
    let payload = OauthSignInPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    EventBuilder::new(self.clone())
      .event(OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>()
  }

  pub async fn sign_out(&self) {
    EventBuilder::new(self.clone())
      .event(SignOut)
      .async_send()
      .await;
  }

  pub fn set_auth_type(&self, auth_type: AuthTypePB) {
    *self.auth_type.write() = auth_type;
  }

  pub async fn init_user(&self) -> UserProfilePB {
    self.sign_up_as_guest().await.user_profile
  }

  pub async fn af_cloud_sign_in_with_email(&self, email: &str) -> FlowyResult<UserProfilePB> {
    let payload = SignInUrlPayloadPB {
      email: email.to_string(),
      auth_type: AuthTypePB::AFCloud,
    };
    let sign_in_url = EventBuilder::new(self.clone())
      .event(GetSignInURL)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<SignInUrlPB>()?
      .sign_in_url;

    let mut map = HashMap::new();
    map.insert(USER_SIGN_IN_URL.to_string(), sign_in_url);
    map.insert(USER_DEVICE_ID.to_string(), uuid::Uuid::new_v4().to_string());
    let payload = OauthSignInPB {
      map,
      auth_type: AuthTypePB::AFCloud,
    };

    let user_profile = EventBuilder::new(self.clone())
      .event(OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()?;

    Ok(user_profile)
  }

  pub async fn supabase_sign_up_with_uuid(
    &self,
    uuid: &str,
    email: Option<String>,
  ) -> FlowyResult<UserProfilePB> {
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid.to_string());
    map.insert(USER_DEVICE_ID.to_string(), uuid.to_string());
    map.insert(
      USER_EMAIL.to_string(),
      email.unwrap_or_else(|| format!("{}@appflowy.io", nanoid!(10))),
    );
    let payload = OauthSignInPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    let user_profile = EventBuilder::new(self.clone())
      .event(OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()?;

    Ok(user_profile)
  }

  // Must sign up/ sign in first
  pub async fn get_current_workspace(&self) -> WorkspaceSettingPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::GetCurrentWorkspace)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::WorkspaceSettingPB>()
  }

  pub async fn get_all_workspace_views(&self) -> Vec<ViewPB> {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadWorkspaceViews)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::RepeatedViewPB>()
      .items
  }

  pub async fn get_views(&self, parent_view_id: &str) -> ViewPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadView)
      .payload(ViewIdPB {
        value: parent_view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn delete_view(&self, view_id: &str) {
    let payload = RepeatedViewIdPB {
      items: vec![view_id.to_string()],
    };

    // delete the view. the view will be moved to trash
    EventBuilder::new(self.clone())
      .event(FolderEvent::DeleteView)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn update_view(&self, changeset: UpdateViewPayloadPB) -> Option<FlowyError> {
    // delete the view. the view will be moved to trash
    EventBuilder::new(self.clone())
      .event(FolderEvent::UpdateView)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn update_view_icon(&self, payload: UpdateViewIconPayloadPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(FolderEvent::UpdateViewIcon)
      .payload(payload)
      .async_send()
      .await
      .error()
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
      index: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn create_document(
    &self,
    parent_id: &str,
    name: String,
    initial_data: Vec<u8>,
  ) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Document,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };
    let view = EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>();

    let payload = OpenDocumentPayloadPB {
      document_id: view.id.clone(),
    };

    let _ = EventBuilder::new(self.clone())
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();

    view
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
      index: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn open_database(&self, view_id: &str) {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetDatabase)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await;
  }

  pub async fn open_document(&self, doc_id: String) -> OpenDocumentData {
    let payload = OpenDocumentPayloadPB {
      document_id: doc_id.clone(),
    };
    let data = EventBuilder::new(self.clone())
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();
    OpenDocumentData { id: doc_id, data }
  }

  pub async fn create_board(&self, parent_id: &str, name: String, initial_data: Vec<u8>) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Board,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn create_calendar(
    &self,
    parent_id: &str,
    name: String,
    initial_data: Vec<u8>,
  ) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Calendar,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
  }

  pub async fn get_database(&self, view_id: &str) -> DatabasePB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetDatabase)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<flowy_database2::entities::DatabasePB>()
  }

  pub async fn get_all_database_fields(&self, view_id: &str) -> RepeatedFieldPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetFields)
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
      .event(DatabaseEvent::CreateTypeOption)
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
      .event(DatabaseEvent::UpdateField)
      .payload(changeset)
      .async_send()
      .await;
  }

  pub async fn delete_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DeleteField)
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
      .event(DatabaseEvent::UpdateFieldType)
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
      .event(DatabaseEvent::DuplicateField)
      .payload(DuplicateFieldPayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_primary_field(&self, database_view_id: &str) -> FieldPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetPrimaryField)
      .payload(DatabaseViewIdPB {
        value: database_view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<FieldPB>()
  }

  pub async fn create_row(
    &self,
    view_id: &str,
    start_row_id: Option<String>,
    data: Option<RowDataPB>,
  ) -> RowMetaPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::CreateRow)
      .payload(CreateRowPayloadPB {
        view_id: view_id.to_string(),
        start_row_id,
        group_id: None,
        data,
      })
      .async_send()
      .await
      .parse::<RowMetaPB>()
  }

  pub async fn delete_row(&self, view_id: &str, row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DeleteRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_row(&self, view_id: &str, row_id: &str) -> OptionalRowPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .parse::<OptionalRowPB>()
  }

  pub async fn get_row_meta(&self, view_id: &str, row_id: &str) -> RowMetaPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRowMeta)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .parse::<RowMetaPB>()
  }

  pub async fn update_row_meta(&self, changeset: UpdateRowMetaChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateRowMeta)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn duplicate_row(&self, view_id: &str, row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DuplicateRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn move_row(&self, view_id: &str, row_id: &str, to_row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::MoveRow)
      .payload(MoveRowPayloadPB {
        view_id: view_id.to_string(),
        from_row_id: row_id.to_string(),
        to_row_id: to_row_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_cell(&self, changeset: CellChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn update_date_cell(&self, changeset: DateChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateDateCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> CellPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetCell)
      .payload(CellIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .parse::<CellPB>()
  }

  pub async fn get_date_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> DateCellDataPB {
    let cell = self.get_cell(view_id, row_id, field_id).await;
    DateCellDataPB::try_from(Bytes::from(cell.data)).unwrap()
  }

  pub async fn get_checklist_cell(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
  ) -> ChecklistCellDataPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetChecklistCellData)
      .payload(CellIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .parse::<ChecklistCellDataPB>()
  }

  pub async fn update_checklist_cell(
    &self,
    changeset: ChecklistCellDataChangesetPB,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateChecklistCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn insert_option(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
    name: &str,
  ) -> Option<FlowyError> {
    let option = EventBuilder::new(self.clone())
      .event(DatabaseEvent::CreateSelectOption)
      .payload(CreateSelectOptionPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
        option_name: name.to_string(),
      })
      .async_send()
      .await
      .parse::<SelectOptionPB>();

    EventBuilder::new(self.clone())
      .event(DatabaseEvent::InsertOrUpdateSelectOption)
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

  pub async fn get_groups(&self, view_id: &str) -> Vec<GroupPB> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetGroups)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedGroupPB>()
      .items
  }

  pub async fn move_group(&self, view_id: &str, from_id: &str, to_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::MoveGroup)
      .payload(MoveGroupPayloadPB {
        view_id: view_id.to_string(),
        from_group_id: from_id.to_string(),
        to_group_id: to_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn set_group_by_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::SetGroupByField)
      .payload(GroupByFieldPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_group(
    &self,
    view_id: &str,
    group_id: &str,
    name: Option<String>,
    visible: Option<bool>,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateGroup)
      .payload(UpdateGroupPB {
        view_id: view_id.to_string(),
        group_id: group_id.to_string(),
        name,
        visible,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_setting(&self, changeset: DatabaseSettingChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateDatabaseSetting)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_all_calendar_events(&self, view_id: &str) -> Vec<CalendarEventPB> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetAllCalendarEvents)
      .payload(CalendarEventRequestPB {
        view_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedCalendarEventPB>()
      .items
  }

  pub async fn get_view(&self, view_id: &str) -> ViewPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadView)
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

#[derive(Clone)]
pub struct TestNotificationSender {
  sender: Arc<Sender<SubscribeObject>>,
}

impl Default for TestNotificationSender {
  fn default() -> Self {
    let (sender, _) = channel(1000);
    Self {
      sender: Arc::new(sender),
    }
  }
}

impl TestNotificationSender {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn subscribe<T>(&self, id: &str, ty: impl Into<i32> + Send) -> tokio::sync::mpsc::Receiver<T>
  where
    T: TryFrom<Bytes, Error = ProtobufError> + Send + 'static,
  {
    let id = id.to_string();
    let (tx, rx) = tokio::sync::mpsc::channel::<T>(10);
    let mut receiver = self.sender.subscribe();
    let ty = ty.into();
    tokio::spawn(async move {
      // DatabaseNotification::DidUpdateDatabaseSnapshotState
      while let Ok(value) = receiver.recv().await {
        if value.id == id && value.ty == ty {
          if let Some(payload) = value.payload {
            match T::try_from(Bytes::from(payload)) {
              Ok(object) => {
                let _ = tx.send(object).await;
              },
              Err(e) => {
                panic!(
                  "Failed to parse notification payload to type: {:?} with error: {}",
                  std::any::type_name::<T>(),
                  e
                );
              },
            }
          }
        }
      }
    });
    rx
  }

  pub fn subscribe_with_condition<T, F>(&self, id: &str, when: F) -> tokio::sync::mpsc::Receiver<T>
  where
    T: TryFrom<Bytes, Error = ProtobufError> + Send + 'static,
    F: Fn(&T) -> bool + Send + 'static,
  {
    let id = id.to_string();
    let (tx, rx) = tokio::sync::mpsc::channel::<T>(10);
    let mut receiver = self.sender.subscribe();
    tokio::spawn(async move {
      while let Ok(value) = receiver.recv().await {
        if value.id == id {
          if let Some(payload) = value.payload {
            if let Ok(object) = T::try_from(Bytes::from(payload)) {
              if when(&object) {
                let _ = tx.send(object).await;
              }
            }
          }
        }
      }
    });
    rx
  }
}

impl NotificationSender for TestNotificationSender {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
    let _ = self.sender.send(subject);
    Ok(())
  }
}

pub struct Cleaner(PathBuf);

impl Cleaner {
  pub fn new(dir: PathBuf) -> Self {
    Cleaner(dir)
  }

  fn cleanup(dir: &PathBuf) {
    let _ = std::fs::remove_dir_all(dir);
  }
}

impl Drop for Cleaner {
  fn drop(&mut self) {
    Self::cleanup(&self.0)
  }
}

pub fn third_party_sign_up_param(uuid: String) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid);
  params.insert(
    USER_EMAIL.to_string(),
    format!("{}@test.com", Uuid::new_v4()),
  );
  params.insert(USER_DEVICE_ID.to_string(), Uuid::new_v4().to_string());
  params
}

pub fn assert_document_data_equal(collab_update: &[u8], doc_id: &str, expected: DocumentData) {
  let collab = MutexCollab::new(CollabOrigin::Server, doc_id, vec![]);
  collab.lock().with_origin_transact_mut(|txn| {
    let update = Update::decode_v1(collab_update).unwrap();
    txn.apply_update(update);
  });
  let document = Document::open(Arc::new(collab)).unwrap();
  let actual = document.get_document_data().unwrap();
  assert_eq!(actual, expected);
}
