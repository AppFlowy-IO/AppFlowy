use flowy_collaboration::entities::document_info::DocumentInfo;
use flowy_folder::event_map::FolderEvent::*;
use flowy_folder_data_model::entities::{
    app::{App, AppId, CreateAppRequest, QueryAppRequest, UpdateAppRequest},
    trash::{RepeatedTrash, TrashId, TrashType},
    view::{CreateViewRequest, QueryViewRequest, UpdateViewRequest, View, ViewType},
    workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest, RepeatedWorkspace, Workspace},
};
use flowy_test::{event_builder::*, FlowySDKTest};

pub async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspaceRequest {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FolderEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .request(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

pub async fn read_workspace(sdk: &FlowySDKTest, workspace_id: Option<String>) -> Vec<Workspace> {
    let request = QueryWorkspaceRequest { workspace_id };
    let repeated_workspace = FolderEventBuilder::new(sdk.clone())
        .event(ReadWorkspaces)
        .request(request.clone())
        .async_send()
        .await
        .parse::<RepeatedWorkspace>();

    let workspaces;
    if let Some(workspace_id) = &request.workspace_id {
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
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(CreateApp)
        .request(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

pub async fn read_app(sdk: &FlowySDKTest, app_id: &str) -> App {
    let request = QueryAppRequest {
        app_ids: vec![app_id.to_owned()],
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(ReadApp)
        .request(request)
        .async_send()
        .await
        .parse::<App>();

    app
}

pub async fn update_app(sdk: &FlowySDKTest, app_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateAppRequest {
        app_id: app_id.to_string(),
        name,
        desc,
        color_style: None,
        is_trash: None,
    };

    FolderEventBuilder::new(sdk.clone())
        .event(UpdateApp)
        .request(request)
        .async_send()
        .await;
}

pub async fn delete_app(sdk: &FlowySDKTest, app_id: &str) {
    let request = AppId {
        app_id: app_id.to_string(),
    };

    FolderEventBuilder::new(sdk.clone())
        .event(DeleteApp)
        .request(request)
        .async_send()
        .await;
}

pub async fn create_view(sdk: &FlowySDKTest, app_id: &str, name: &str, desc: &str, view_type: ViewType) -> View {
    let request = CreateViewRequest {
        belong_to_id: app_id.to_string(),
        name: name.to_string(),
        desc: desc.to_string(),
        thumbnail: None,
        view_type,
    };
    let view = FolderEventBuilder::new(sdk.clone())
        .event(CreateView)
        .request(request)
        .async_send()
        .await
        .parse::<View>();
    view
}

pub async fn read_view(sdk: &FlowySDKTest, view_ids: Vec<String>) -> View {
    let request = QueryViewRequest { view_ids };
    FolderEventBuilder::new(sdk.clone())
        .event(ReadView)
        .request(request)
        .async_send()
        .await
        .parse::<View>()
}

pub async fn update_view(sdk: &FlowySDKTest, view_id: &str, name: Option<String>, desc: Option<String>) {
    let request = UpdateViewRequest {
        view_id: view_id.to_string(),
        name,
        desc,
        thumbnail: None,
    };
    FolderEventBuilder::new(sdk.clone())
        .event(UpdateView)
        .request(request)
        .async_send()
        .await;
}

pub async fn delete_view(sdk: &FlowySDKTest, view_ids: Vec<String>) {
    let request = QueryViewRequest { view_ids };
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteView)
        .request(request)
        .async_send()
        .await;
}

pub async fn open_document(sdk: &FlowySDKTest, view_id: &str) -> DocumentInfo {
    let request = QueryViewRequest {
        view_ids: vec![view_id.to_owned()],
    };
    FolderEventBuilder::new(sdk.clone())
        .event(OpenDocument)
        .request(request)
        .async_send()
        .await
        .parse::<DocumentInfo>()
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
        .request(id)
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
        .request(id)
        .async_send()
        .await;
}

pub async fn delete_all_trash(sdk: &FlowySDKTest) {
    FolderEventBuilder::new(sdk.clone())
        .event(DeleteAllTrash)
        .async_send()
        .await;
}
