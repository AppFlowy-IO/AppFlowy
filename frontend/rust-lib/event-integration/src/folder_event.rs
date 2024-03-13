use flowy_folder::entities::icon::UpdateViewIconPayloadPB;
use flowy_folder::event_map::FolderEvent;
use flowy_folder::event_map::FolderEvent::*;
use flowy_folder::{entities::*, ViewLayout};
use flowy_user::entities::{
  AddWorkspaceMemberPB, QueryWorkspacePB, RemoveWorkspaceMemberPB, RepeatedWorkspaceMemberPB,
  WorkspaceMemberPB,
};
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserEvent;
use tokio::time::sleep;

use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  pub async fn add_workspace_member(&self, workspace_id: &str, email: &str) {
    EventBuilder::new(self.clone())
      .event(UserEvent::AddWorkspaceMember)
      .payload(AddWorkspaceMemberPB {
        workspace_id: workspace_id.to_string(),
        email: email.to_string(),
      })
      .async_send()
      .await;
  }

  pub async fn delete_workspace_member(&self, workspace_id: &str, email: &str) {
    EventBuilder::new(self.clone())
      .event(UserEvent::RemoveWorkspaceMember)
      .payload(RemoveWorkspaceMemberPB {
        workspace_id: workspace_id.to_string(),
        email: email.to_string(),
      })
      .async_send()
      .await;
  }

  pub async fn get_workspace_members(&self, workspace_id: &str) -> Vec<WorkspaceMemberPB> {
    EventBuilder::new(self.clone())
      .event(UserEvent::GetWorkspaceMember)
      .payload(QueryWorkspacePB {
        workspace_id: workspace_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedWorkspaceMemberPB>()
      .items
  }

  pub async fn get_current_workspace(&self) -> WorkspacePB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadCurrentWorkspace)
      .async_send()
      .await
      .parse::<WorkspacePB>()
  }

  pub async fn get_all_workspace_views(&self) -> Vec<ViewPB> {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadWorkspaceViews)
      .async_send()
      .await
      .parse::<RepeatedViewPB>()
      .items
  }

  pub async fn get_trash(&self) -> RepeatedTrashPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ListTrashItems)
      .async_send()
      .await
      .parse::<RepeatedTrashPB>()
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
      .parse::<ViewPB>()
  }

  pub async fn get_view(&self, view_id: &str) -> ViewPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::GetView)
      .payload(ViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn import_data(&self, data: ImportPB) -> ViewPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ImportData)
      .payload(data)
      .async_send()
      .await
      .parse::<ViewPB>()
  }
}

pub struct ViewTest {
  pub sdk: EventIntegrationTest,
  pub workspace: WorkspacePB,
  pub child_view: ViewPB,
}
impl ViewTest {
  #[allow(dead_code)]
  pub async fn new(sdk: &EventIntegrationTest, layout: ViewLayout, data: Vec<u8>) -> Self {
    let workspace = sdk.folder_manager.get_current_workspace().await.unwrap();

    let payload = CreateViewPayloadPB {
      parent_view_id: workspace.id.clone(),
      name: "View A".to_string(),
      desc: "".to_string(),
      thumbnail: Some("http://1.png".to_string()),
      layout: layout.into(),
      initial_data: data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };

    let view = EventBuilder::new(sdk.clone())
      .event(CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>();

    Self {
      sdk: sdk.clone(),
      workspace,
      child_view: view,
    }
  }

  pub async fn new_grid_view(sdk: &EventIntegrationTest, data: Vec<u8>) -> Self {
    // TODO(nathan): remove this sleep
    // workaround for the rows that are created asynchronously
    let this = Self::new(sdk, ViewLayout::Grid, data).await;
    sleep(tokio::time::Duration::from_secs(2)).await;
    this
  }

  pub async fn new_board_view(sdk: &EventIntegrationTest, data: Vec<u8>) -> Self {
    let this = Self::new(sdk, ViewLayout::Board, data).await;
    sleep(tokio::time::Duration::from_secs(2)).await;
    this
  }

  pub async fn new_calendar_view(sdk: &EventIntegrationTest, data: Vec<u8>) -> Self {
    let this = Self::new(sdk, ViewLayout::Calendar, data).await;
    sleep(tokio::time::Duration::from_secs(2)).await;
    this
  }
}

#[allow(dead_code)]
async fn create_workspace(sdk: &EventIntegrationTest, name: &str, desc: &str) -> WorkspacePB {
  let request = CreateWorkspacePayloadPB {
    name: name.to_owned(),
    desc: desc.to_owned(),
  };

  EventBuilder::new(sdk.clone())
    .event(CreateWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<WorkspacePB>()
}
