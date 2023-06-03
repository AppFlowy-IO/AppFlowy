use crate::event_builder::EventBuilder;
use crate::FlowyCoreTest;
use flowy_folder2::entities::*;
use flowy_folder2::event_map::FolderEvent::*;

pub struct ViewTest {
  pub sdk: FlowyCoreTest,
  pub workspace: WorkspacePB,
  pub parent_view: ViewPB,
  pub child_view: ViewPB,
}

impl ViewTest {
  #[allow(dead_code)]
  pub async fn new(sdk: &FlowyCoreTest, layout: ViewLayoutPB, data: Vec<u8>) -> Self {
    let workspace = create_workspace(sdk, "Workspace", "").await;
    open_workspace(sdk, &workspace.id).await;
    let app = create_app(sdk, "App", "AppFlowy GitHub Project", &workspace.id).await;
    let view = create_view(sdk, &app.id, layout, data).await;
    Self {
      sdk: sdk.clone(),
      workspace,
      parent_view: app,
      child_view: view,
    }
  }

  pub async fn new_grid_view(sdk: &FlowyCoreTest, data: Vec<u8>) -> Self {
    Self::new(sdk, ViewLayoutPB::Grid, data).await
  }

  pub async fn new_board_view(sdk: &FlowyCoreTest, data: Vec<u8>) -> Self {
    Self::new(sdk, ViewLayoutPB::Board, data).await
  }

  pub async fn new_calendar_view(sdk: &FlowyCoreTest, data: Vec<u8>) -> Self {
    Self::new(sdk, ViewLayoutPB::Calendar, data).await
  }

  pub async fn new_document_view(sdk: &FlowyCoreTest) -> Self {
    Self::new(sdk, ViewLayoutPB::Document, vec![]).await
  }
}

async fn create_workspace(sdk: &FlowyCoreTest, name: &str, desc: &str) -> WorkspacePB {
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

async fn open_workspace(sdk: &FlowyCoreTest, workspace_id: &str) {
  let payload = WorkspaceIdPB {
    value: Some(workspace_id.to_owned()),
  };
  let _ = EventBuilder::new(sdk.clone())
    .event(OpenWorkspace)
    .payload(payload)
    .async_send()
    .await;
}

async fn create_app(sdk: &FlowyCoreTest, name: &str, desc: &str, workspace_id: &str) -> ViewPB {
  let create_app_request = CreateViewPayloadPB {
    parent_view_id: workspace_id.to_owned(),
    name: name.to_string(),
    desc: desc.to_string(),
    thumbnail: None,
    layout: ViewLayoutPB::Document,
    initial_data: vec![],
    meta: Default::default(),
    set_as_current: true,
  };

  EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(create_app_request)
    .async_send()
    .await
    .parse::<ViewPB>()
}

async fn create_view(
  sdk: &FlowyCoreTest,
  app_id: &str,
  layout: ViewLayoutPB,
  data: Vec<u8>,
) -> ViewPB {
  let payload = CreateViewPayloadPB {
    parent_view_id: app_id.to_string(),
    name: "View A".to_string(),
    desc: "".to_string(),
    thumbnail: Some("http://1.png".to_string()),
    layout,
    initial_data: data,
    meta: Default::default(),
    set_as_current: true,
  };

  EventBuilder::new(sdk.clone())
    .event(CreateView)
    .payload(payload)
    .async_send()
    .await
    .parse::<ViewPB>()
}
