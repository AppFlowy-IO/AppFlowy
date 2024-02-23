use flowy_core::AppFlowyCore;
use lib_dispatch::prelude::{
  AFPluginDispatcher, AFPluginEventResponse, AFPluginRequest, StatusCode,
};
use tauri::{AppHandle, Manager, State, Wry};

#[derive(Clone, Debug, serde::Deserialize)]
pub struct AFTauriRequest {
  ty: String,
  payload: Vec<u8>,
}

impl std::convert::From<AFTauriRequest> for AFPluginRequest {
  fn from(event: AFTauriRequest) -> Self {
    AFPluginRequest::new(event.ty).payload(event.payload)
  }
}

#[derive(Clone, serde::Serialize)]
pub struct AFTauriResponse {
  code: StatusCode,
  payload: Vec<u8>,
}

impl std::convert::From<AFPluginEventResponse> for AFTauriResponse {
  fn from(response: AFPluginEventResponse) -> Self {
    Self {
      code: response.status_code,
      payload: response.payload.to_vec(),
    }
  }
}

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
pub async fn invoke_request(
  request: AFTauriRequest,
  app_handler: AppHandle<Wry>,
) -> AFTauriResponse {
  let request: AFPluginRequest = request.into();
  let state: State<AppFlowyCore> = app_handler.state();
  let dispatcher = state.inner().dispatcher();
  let response = AFPluginDispatcher::async_send(dispatcher.as_ref(), request).await;
  response.into()
}
