use flowy_collaboration::entities::document_info::BlockInfo;
use flowy_folder::event_map::FolderEvent::*;
use flowy_folder_data_model::entities::view::{RepeatedViewId, ViewId};
use flowy_folder_data_model::entities::workspace::WorkspaceId;
use flowy_folder_data_model::entities::{
    app::{App, AppId, CreateAppPayload, UpdateAppPayload},
    trash::{RepeatedTrash, TrashId, TrashType},
    view::{CreateViewPayload, UpdateViewPayload, View, ViewDataType},
    workspace::{CreateWorkspacePayload, RepeatedWorkspace, Workspace},
};
use flowy_test::{event_builder::*, FlowySDKTest};

pub async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspacePayload {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FolderEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

pub async fn read_workspace(sdk: &FlowySDKTest, workspace_id: Option<String>) -> Vec<Workspace> {
    let request = WorkspaceId { value: workspace_id };
    let repeated_workspace = FolderEventBuilder::new(sdk.clone())
        .event(ReadWorkspaces)
        .payload(request.clone())
        .async_send()
        .await
        .parse::<RepeatedWorkspace>();

    let workspaces;
    if let Some(workspace_id) = &request.value {
        workspaces = repeated_workspace
            .into_inner()
            .into_iter()
            .filter(|workspace| &workspace.id == workspace_id)
            .collect::<Vec<Workspace>>();
        debug_assert_eq!(workspaces.len(), 1);
    } else {
        workspaces = repeated_workspace.items;
    }

    workspaces
}

pub async fn create_app(sdk: &FlowySDKTest, workspace_id: &str, name: &str, desc: &str) -> App {
    let create_app_request = CreateAppPayload {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(CreateApp)
        .payload(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

pub async fn read_app(sdk: &FlowySDKTest, app_id: &str) -> App {
    let request = AppId {
        value: app_id.to_owned(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(ReadApp)
        .payload(request)
        .async_send()
        .await
        .parse::<App>();

    app
}

pub async fn update_app(sdk: &FlowySDKTest, app_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateAppPayload {
        app_id: app_id.to_string(),
        name,
        desc,
        color_style: None,
        is_trash: None,
    };

    FolderEventBuilder::new(sdk.clone())
        .event(UpdateApp)
        .payload(request)
        .async_send()
        .await;
}

pub async fn delete_app(sdk: &FlowySDKTest, app_id: &str) {
    let request = AppId {
        value: app_id.to_string(),
    };

    FolderEventBuilder::new(sdk.clone())
        .event(DeleteApp)
        .payload(request)
        .async_send()
        .await;
}

pub async fn create_view(sdk: &FlowySDKTest, app_id: &str, name: &str, desc: &str, data_type: ViewDataType) -> View {
    let request = CreateViewPayload {
        belong_to_id: app_id.to_string(),
        name: name.to_string(),
        desc: desc.to_string(),
        thumbnail: None,
        data_type,
        ext_data: "".to_string(),
        plugin_type: 0,
    };
    let view = FolderEventBuilder::new(sdk.clone())
        .event(CreateView)
        .payload(request)
        .async_send()
        .await
        .parse::<View>();
    view
}

pub async fn read_view(sdk: &FlowySDKTest, view_id: &str) -> View {
    let view_id: ViewId = view_id.into();
    FolderEventBuilder::new(sdk.clone())
        .event(ReadView)
        .payload(view_id)
        .async_send()
        .await
        .parse::<View>()
}

pub async fn update_view(sdk: &FlowySDKTest, view_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateViewPayload {
        view_id: view_id.to_string(),
        name,
        desc,
        thumbnail: None,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(UpdateView)
        .payload(request)
        .async_send()
        .await;
}

pub async fn delete_view(sdk: &FlowySDKTest, view_ids: Vec<String>) {
    let request = RepeatedViewId { items: view_ids };
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteView)
        .payload(request)
        .async_send()
        .await;
}

pub async fn open_document(sdk: &FlowySDKTest, view_id: &str) -> BlockInfo {
    let view_id: ViewId = view_id.into();
    FolderEventBuilder::new(sdk.clone())
        .event(SetLatestView)
        .payload(view_id)
        .async_send()
        .await
        .parse::<BlockInfo>()
}

pub async fn read_trash(sdk: &FlowySDKTest) -> RepeatedTrash {
    FolderEventBuilder::new(sdk.clone())
        .event(ReadTrash)
        .async_send()
        .await
        .parse::<RepeatedTrash>()
}

pub async fn restore_app_from_trash(sdk: &FlowySDKTest, app_id: &str) {
    let id = TrashId {
        id: app_id.to_owned(),
        ty: TrashType::TrashApp,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(PutbackTrash)
        .payload(id)
        .async_send()
        .await;
}

pub async fn restore_view_from_trash(sdk: &FlowySDKTest, view_id: &str) {
    let id = TrashId {
        id: view_id.to_owned(),
        ty: TrashType::TrashView,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(PutbackTrash)
        .payload(id)
        .async_send()
        .await;
}

pub async fn delete_all_trash(sdk: &FlowySDKTest) {
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteAllTrash)
        .async_send()
        .await;
}
