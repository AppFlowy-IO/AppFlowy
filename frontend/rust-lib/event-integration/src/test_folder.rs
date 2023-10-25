use flowy_folder2::entities::icon::UpdateViewIconPayloadPB;
use flowy_folder2::entities::*;
use flowy_folder2::event_map::FolderEvent;
use flowy_folder2::event_map::FolderEvent::*;
use flowy_user::errors::FlowyError;

use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  // Must sign up/ sign in first
  pub async fn get_current_workspace(&self) -> WorkspaceSettingPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::GetCurrentWorkspace)
      .async_send()
      .await
      .parse::<WorkspaceSettingPB>()
  }

  pub async fn get_all_workspace_views(&self) -> Vec<ViewPB> {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadWorkspaceViews)
      .async_send()
      .await
      .parse::<RepeatedViewPB>()
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
      .parse::<ViewPB>()
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
      .event(FolderEvent::ReadView)
      .payload(ViewIdPB {
        value: view_id.to_string(),
      })
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
    let workspace = create_workspace(sdk, "Workspace", "").await;
    let payload = WorkspaceIdPB {
      value: Some(workspace.id.clone()),
    };
    let _ = EventBuilder::new(sdk.clone())
      .event(OpenWorkspace)
      .payload(payload)
      .async_send()
      .await;

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
