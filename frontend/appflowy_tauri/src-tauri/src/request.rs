use bytes::Bytes;
use flowy_core::FlowySDK;
use lib_dispatch::prelude::{
    AFPlugin, AFPluginDispatcher, AFPluginEvent, AFPluginEventResponse, AFPluginRequest, Payload,
    StatusCode,
};
use tauri::{AppHandle, Event, Manager, State, Wry};

#[derive(Clone, serde::Deserialize)]
pub struct AFTauriRequest {
    ty: String,
    payload: Bytes,
}

impl std::convert::From<AFTauriRequest> for AFPluginRequest {
    fn from(event: AFTauriRequest) -> Self {
        AFPluginRequest::new(event.ty).payload(event.payload)
    }
}

#[derive(Clone, serde::Serialize)]
pub struct AFTauriResponse {
    code: StatusCode,
    payload: Payload,
}

impl std::convert::From<AFPluginEventResponse> for AFTauriResponse {
    fn from(response: AFPluginEventResponse) -> Self {
        Self {
            code: response.status_code,
            payload: response.payload,
        }
    }
}

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
// #[tracing::instrument(level = "trace", skip_all)]
#[tauri::command]
pub async fn invoke_request(
    request: AFTauriRequest,
    app_handler: AppHandle<Wry>,
) -> AFTauriResponse {
    let request: AFPluginRequest = request.into();
    let state: State<FlowySDK> = app_handler.state();
    let dispatcher = state.inner().dispatcher();
    let response = AFPluginDispatcher::async_send(dispatcher, request).await;
    response.into()
}
