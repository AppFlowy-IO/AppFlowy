use crate::local_server::persistence::LocalDocumentCloudPersistence;
use async_stream::stream;
use bytes::Bytes;
use document_model::document::{
  CreateDocumentParams, DocumentId, DocumentInfo, ResetDocumentParams,
};
use flowy_client_sync::errors::SyncError;
use flowy_document::DocumentCloudService;
use flowy_error::{internal_error, FlowyError};
use flowy_server_sync::server_document::ServerDocumentManager;
use flowy_server_sync::server_folder::ServerFolderManager;
use flowy_sync::{RevisionSyncResponse, RevisionUser};
use flowy_user::entities::UserProfilePB;
use flowy_user::event_map::UserCloudService;

use flowy_user::uid::UserIDGenerator;
use futures_util::stream::StreamExt;
use lib_infra::future::FutureResult;
use lib_ws::{WSChannel, WebSocketRawMessage};

use parking_lot::RwLock;
use std::{
  convert::{TryFrom, TryInto},
  fmt::Debug,
  sync::Arc,
};
use tokio::sync::{broadcast, mpsc, mpsc::UnboundedSender};
use user_model::*;
use ws_model::ws_revision::{ClientRevisionWSData, ClientRevisionWSDataType};

pub struct LocalServer {
  id_generator: RwLock<UserIDGenerator>,
  doc_manager: Arc<ServerDocumentManager>,
  folder_manager: Arc<ServerFolderManager>,
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
  client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
  client_ws_receiver: broadcast::Sender<WebSocketRawMessage>,
}

impl LocalServer {
  pub fn new(
    client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
    client_ws_receiver: broadcast::Sender<WebSocketRawMessage>,
  ) -> Self {
    let persistence = Arc::new(LocalDocumentCloudPersistence::default());
    let doc_manager = Arc::new(ServerDocumentManager::new(persistence.clone()));
    let folder_manager = Arc::new(ServerFolderManager::new(persistence));
    let stop_tx = RwLock::new(None);
    let id_generator = RwLock::new(UserIDGenerator::new(1));
    LocalServer {
      id_generator,
      doc_manager,
      folder_manager,
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
      doc_manager: self.doc_manager.clone(),
      folder_manager: self.folder_manager.clone(),
      stop_rx: Some(stop_rx),
      client_ws_sender: self.client_ws_sender.clone(),
      client_ws_receiver: Some(self.client_ws_receiver.subscribe()),
    };
    tokio::spawn(runner.run());
  }
}

struct LocalWebSocketRunner {
  doc_manager: Arc<ServerDocumentManager>,
  folder_manager: Arc<ServerFolderManager>,
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

  async fn handle_message(&self, message: WebSocketRawMessage) -> Result<(), FlowyError> {
    let bytes = Bytes::from(message.data);
    let client_data = ClientRevisionWSData::try_from(bytes).map_err(internal_error)?;
    match message.channel {
      WSChannel::Document => {
        self
          .handle_document_client_data(client_data, "".to_owned())
          .await?;
        Ok(())
      },
      WSChannel::Folder => {
        self
          .handle_folder_client_data(client_data, "".to_owned())
          .await?;
        Ok(())
      },
      WSChannel::Database => {
        todo!("Implement database web socket channel")
      },
    }
  }

  pub async fn handle_folder_client_data(
    &self,
    client_data: ClientRevisionWSData,
    user_id: String,
  ) -> Result<(), SyncError> {
    tracing::trace!(
      "[LocalFolderServer] receive: {}:{}-{:?} ",
      client_data.object_id,
      client_data.rev_id,
      client_data.ty,
    );
    let client_ws_sender = self.client_ws_sender.clone();
    let user = Arc::new(LocalRevisionUser {
      user_id,
      client_ws_sender,
      channel: WSChannel::Folder,
    });
    let ty = client_data.ty.clone();
    match ty {
      ClientRevisionWSDataType::ClientPushRev => {
        self
          .folder_manager
          .handle_client_revisions(user, client_data)
          .await?;
      },
      ClientRevisionWSDataType::ClientPing => {
        self
          .folder_manager
          .handle_client_ping(user, client_data)
          .await?;
      },
    }
    Ok(())
  }

  pub async fn handle_document_client_data(
    &self,
    client_data: ClientRevisionWSData,
    user_id: String,
  ) -> Result<(), SyncError> {
    tracing::trace!(
      "[LocalDocumentServer] receive: {}:{}-{:?} ",
      client_data.object_id,
      client_data.rev_id,
      client_data.ty,
    );
    let client_ws_sender = self.client_ws_sender.clone();
    let user = Arc::new(LocalRevisionUser {
      user_id,
      client_ws_sender,
      channel: WSChannel::Document,
    });
    let ty = client_data.ty.clone();
    match ty {
      ClientRevisionWSDataType::ClientPushRev => {
        self
          .doc_manager
          .handle_client_revisions(user, client_data)
          .await?;
      },
      ClientRevisionWSDataType::ClientPing => {
        self
          .doc_manager
          .handle_client_ping(user, client_data)
          .await?;
      },
    }
    Ok(())
  }
}

#[derive(Debug)]
struct LocalRevisionUser {
  user_id: String,
  client_ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
  channel: WSChannel,
}

impl RevisionUser for LocalRevisionUser {
  fn user_id(&self) -> String {
    self.user_id.clone()
  }

  fn receive(&self, resp: RevisionSyncResponse) {
    let sender = self.client_ws_sender.clone();
    let send_fn =
      |sender: UnboundedSender<WebSocketRawMessage>, msg: WebSocketRawMessage| match sender
        .send(msg)
      {
        Ok(_) => {},
        Err(e) => {
          tracing::error!("LocalDocumentUser send message failed: {}", e);
        },
      };
    let channel = self.channel.clone();

    tokio::spawn(async move {
      match resp {
        RevisionSyncResponse::Pull(data) => {
          let bytes: Bytes = data.try_into().unwrap();
          let msg = WebSocketRawMessage {
            channel,
            data: bytes.to_vec(),
          };
          send_fn(sender, msg);
        },
        RevisionSyncResponse::Push(data) => {
          let bytes: Bytes = data.try_into().unwrap();
          let msg = WebSocketRawMessage {
            channel,
            data: bytes.to_vec(),
          };
          send_fn(sender, msg);
        },
        RevisionSyncResponse::Ack(data) => {
          let bytes: Bytes = data.try_into().unwrap();
          let msg = WebSocketRawMessage {
            channel,
            data: bytes.to_vec(),
          };
          send_fn(sender, msg);
        },
      }
    });
  }
}

impl UserCloudService for LocalServer {
  fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
    let uid = self.id_generator.write().next_id();
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
    let uid = self.id_generator.write().next_id();
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

impl DocumentCloudService for LocalServer {
  fn create_document(
    &self,
    _token: &str,
    _params: CreateDocumentParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn fetch_document(
    &self,
    _token: &str,
    _params: DocumentId,
  ) -> FutureResult<Option<DocumentInfo>, FlowyError> {
    FutureResult::new(async { Ok(None) })
  }

  fn update_document_content(
    &self,
    _token: &str,
    _params: ResetDocumentParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }
}
