use std::sync::Arc;

use async_stream::stream;
use futures_util::stream::StreamExt;
use lazy_static::lazy_static;
use parking_lot::{Mutex, RwLock};
use tokio::sync::{broadcast, mpsc};

use flowy_error::FlowyError;
use flowy_user::entities::{
  SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams,
  UserProfilePB,
};
use flowy_user::event_map::UserCloudService;
use flowy_user::uid::UserIDGenerator;
use lib_infra::future::FutureResult;
use lib_ws::WebSocketRawMessage;

use crate::local_server::persistence::LocalDocumentCloudPersistence;

lazy_static! {
  static ref ID_GEN: Mutex<UserIDGenerator> = Mutex::new(UserIDGenerator::new(1));
}

pub struct LocalServer {
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
  client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
  client_ws_receiver: broadcast::Sender<WebSocketRawMessage>,
}

impl LocalServer {
  pub fn new(
    client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
    client_ws_receiver: broadcast::Sender<WebSocketRawMessage>,
  ) -> Self {
    let _persistence = Arc::new(LocalDocumentCloudPersistence::default());
    let stop_tx = RwLock::new(None);
    LocalServer {
      stop_tx,
      client_ws_sender,
      client_ws_receiver,
    }
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.read().clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }

  pub fn run(&self) {
    let (stop_tx, stop_rx) = mpsc::channel(1);
    *self.stop_tx.write() = Some(stop_tx);
    let runner = LocalWebSocketRunner {
      stop_rx: Some(stop_rx),
      client_ws_sender: self.client_ws_sender.clone(),
      client_ws_receiver: Some(self.client_ws_receiver.subscribe()),
    };
    tokio::spawn(runner.run());
  }
}

struct LocalWebSocketRunner {
  stop_rx: Option<mpsc::Receiver<()>>,
  client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
  client_ws_receiver: Option<broadcast::Receiver<WebSocketRawMessage>>,
}

impl LocalWebSocketRunner {
  pub async fn run(mut self) {
    let mut stop_rx = self.stop_rx.take().expect("Only run once");
    let mut client_ws_receiver = self.client_ws_receiver.take().expect("Only run once");
    let stream = stream! {
        loop {
            tokio::select! {
                result = client_ws_receiver.recv() => {
                    match result {
                        Ok(msg) => yield msg,
                        Err(_e) => {},
                    }
                },
                _ = stop_rx.recv() => {
                    tracing::trace!("[LocalWebSocketRunner] stop");
                    break
                },
            };
        }
    };
    stream
      .for_each(|message| async {
        match self.handle_message(message).await {
          Ok(_) => {},
          Err(e) => tracing::error!("[LocalWebSocketRunner]: {}", e),
        }
      })
      .await;
  }

  async fn handle_message(&self, _message: WebSocketRawMessage) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn handle_folder_client_data(
    &self,
    _client_data: String,
    _user_id: String,
  ) -> Result<(), String> {
    Ok(())
  }

  pub async fn handle_document_client_data(
    &self,
    _client_data: String,
    _user_id: String,
  ) -> Result<(), String> {
    Ok(())
  }
}

impl UserCloudService for LocalServer {
  fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
    let uid = ID_GEN.lock().next_id();
    FutureResult::new(async move {
      Ok(SignUpResponse {
        user_id: uid,
        name: params.name,
        email: params.email,
        token: "".to_string(),
      })
    })
  }

  fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
    let uid = ID_GEN.lock().next_id();
    FutureResult::new(async move {
      Ok(SignInResponse {
        user_id: uid,
        name: params.name,
        email: params.email,
        token: "".to_string(),
      })
    })
  }

  fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_user(
    &self,
    _token: &str,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user(&self, _token: &str) -> FutureResult<UserProfilePB, FlowyError> {
    FutureResult::new(async { Ok(UserProfilePB::default()) })
  }

  fn ws_addr(&self) -> String {
    "ws://localhost:8000/ws/".to_owned()
  }
}
