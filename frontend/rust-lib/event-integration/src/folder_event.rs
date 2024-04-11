use flowy_folder::entities::icon::UpdateViewIconPayloadPB;
use flowy_folder::entities::*;
use flowy_folder::event_map::FolderEvent;
use flowy_folder::event_map::FolderEvent::*;
use flowy_user::entities::{
  AcceptWorkspaceInvitationPB, AddWorkspaceMemberPB, QueryWorkspacePB, RemoveWorkspaceMemberPB,
  RepeatedWorkspaceInvitationPB, RepeatedWorkspaceMemberPB, WorkspaceMemberInvitationPB,
  WorkspaceMemberPB,
};
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserEvent;
use flowy_user_pub::entities::Role;

use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  pub async fn add_workspace_member(&self, workspace_id: &str, email: &str) {
    if let Some(err) = EventBuilder::new(self.clone())
      .event(UserEvent::AddWorkspaceMember)
      .payload(AddWorkspaceMemberPB {
        workspace_id: workspace_id.to_string(),
        email: email.to_string(),
      })
      .async_send()
      .await
      .error()
    {
      panic!("Add workspace member failed: {:?}", err);
    }
  }

  pub async fn invite_workspace_member(&self, workspace_id: &str, email: &str, role: Role) {
    EventBuilder::new(self.clone())
      .event(UserEvent::InviteWorkspaceMember)
      .payload(WorkspaceMemberInvitationPB {
        workspace_id: workspace_id.to_string(),
        invitee_email: email.to_string(),
        role: role.into(),
      })
      .async_send()
      .await
  }

  pub async fn list_workspace_invitations(&self) -> RepeatedWorkspaceInvitationPB {
    EventBuilder::new(self.clone())
      .event(UserEvent::ListWorkspaceInvitations)
      .async_send()
      .await
      .parse()
  }

  pub async fn accept_workspace_invitation(&self, invitation_id: &str) {
    if let Some(err) = EventBuilder::new(self.clone())
      .event(UserEvent::AcceptWorkspaceInvitation)
      .payload(AcceptWorkspaceInvitationPB {
        invite_id: invitation_id.to_string(),
      })
      .async_send()
      .await
      .error()
    {
      panic!("Accept workspace invitation failed: {:?}", err)
    };
  }

  pub async fn delete_workspace_member(&self, workspace_id: &str, email: &str) {
    if let Some(err) = EventBuilder::new(self.clone())
      .event(UserEvent::RemoveWorkspaceMember)
      .payload(RemoveWorkspaceMemberPB {
        workspace_id: workspace_id.to_string(),
        email: email.to_string(),
      })
      .async_send()
      .await
      .error()
    {
      panic!("Delete workspace member failed: {:?}", err)
    };
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
      .event(FolderEvent::ReadCurrentWorkspaceViews)
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
    if let Some(err) = EventBuilder::new(self.clone())
      .event(FolderEvent::DeleteView)
      .payload(payload)
      .async_send()
      .await
      .error()
    {
      panic!("Delete view failed: {:?}", err)
    };
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
      section: None,
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
  pub async fn new(sdk: &EventIntegrationTest, layout: ViewLayoutPB, data: Vec<u8>) -> Self {
    let workspace = sdk.folder_manager.get_current_workspace().await.unwrap();

    let payload = CreateViewPayloadPB {
      parent_view_id: workspace.id.clone(),
      name: "View A".to_string(),
      desc: "".to_string(),
      thumbnail: Some("http://1.png".to_string()),
      layout,
      initial_data: data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
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
    Self::new(sdk, ViewLayoutPB::Grid, data).await
  }

  pub async fn new_board_view(sdk: &EventIntegrationTest, data: Vec<u8>) -> Self {
    Self::new(sdk, ViewLayoutPB::Board, data).await
  }

  pub async fn new_calendar_view(sdk: &EventIntegrationTest, data: Vec<u8>) -> Self {
    Self::new(sdk, ViewLayoutPB::Calendar, data).await
  }
}

#[allow(dead_code)]
async fn create_workspace(sdk: &EventIntegrationTest, name: &str, desc: &str) -> WorkspacePB {
  let request = CreateWorkspacePayloadPB {
    name: name.to_owned(),
    desc: desc.to_owned(),
  };

  EventBuilder::new(sdk.clone())
    .event(CreateFolderWorkspace)
    .payload(request)
    .async_send()
    .await
    .parse::<WorkspacePB>()
}
