use crate::local_server::persistence::LocalDocumentCloudPersistence;
use async_stream::stream;
use bytes::Bytes;
use flowy_error::{internal_error, FlowyError};
use flowy_folder::event_map::FolderCouldServiceV1;
use flowy_sync::{
    errors::CollaborateError,
    server_document::ServerDocumentManager,
    server_folder::ServerFolderManager,
    synchronizer::{RevisionSyncResponse, RevisionUser},
};
use futures_util::stream::StreamExt;
use lib_ws::{WSChannel, WebSocketRawMessage};
use nanoid::nanoid;
use parking_lot::RwLock;
use std::{
    convert::{TryFrom, TryInto},
    fmt::Debug,
    sync::Arc,
};
use tokio::sync::{broadcast, mpsc, mpsc::UnboundedSender};

pub struct LocalServer {
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

        LocalServer {
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
                    Ok(_) => {}
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
                self.handle_document_client_data(client_data, "".to_owned()).await?;
                Ok(())
            }
            WSChannel::Folder => {
                self.handle_folder_client_data(client_data, "".to_owned()).await?;
                Ok(())
            }
            WSChannel::Grid => {
                todo!("Implement grid web socket channel")
            }
        }
    }

    pub async fn handle_folder_client_data(
        &self,
        client_data: ClientRevisionWSData,
        user_id: String,
    ) -> Result<(), CollaborateError> {
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
                self.folder_manager.handle_client_revisions(user, client_data).await?;
            }
            ClientRevisionWSDataType::ClientPing => {
                self.folder_manager.handle_client_ping(user, client_data).await?;
            }
        }
        Ok(())
    }

    pub async fn handle_document_client_data(
        &self,
        client_data: ClientRevisionWSData,
        user_id: String,
    ) -> Result<(), CollaborateError> {
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
                self.doc_manager.handle_client_revisions(user, client_data).await?;
            }
            ClientRevisionWSDataType::ClientPing => {
                self.doc_manager.handle_client_ping(user, client_data).await?;
            }
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
        let send_fn = |sender: UnboundedSender<WebSocketRawMessage>, msg: WebSocketRawMessage| match sender.send(msg) {
            Ok(_) => {}
            Err(e) => {
                tracing::error!("LocalDocumentUser send message failed: {}", e);
            }
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
                }
                RevisionSyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        channel,
                        data: bytes.to_vec(),
                    };
                    send_fn(sender, msg);
                }
                RevisionSyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        channel,
                        data: bytes.to_vec(),
                    };
                    send_fn(sender, msg);
                }
            }
        });
    }
}

use flowy_document::DocumentCloudService;
use flowy_folder::entities::{
    app::{AppIdPB, CreateAppParams, UpdateAppParams},
    trash::RepeatedTrashIdPB,
    view::{CreateViewParams, RepeatedViewIdPB, UpdateViewParams, ViewIdPB},
    workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceIdPB},
};
use flowy_http_model::document::{CreateDocumentParams, DocumentId, DocumentPayload, ResetDocumentParams};
use flowy_http_model::ws_data::{ClientRevisionWSData, ClientRevisionWSDataType};
use flowy_user::entities::{
    SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfilePB,
};
use flowy_user::event_map::UserCloudService;
use folder_rev_model::{gen_app_id, gen_workspace_id, AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
use lib_infra::{future::FutureResult, util::timestamp};

impl FolderCouldServiceV1 for LocalServer {
    fn init(&self) {}

    fn create_workspace(
        &self,
        _token: &str,
        params: CreateWorkspaceParams,
    ) -> FutureResult<WorkspaceRevision, FlowyError> {
        let time = timestamp();
        let workspace = WorkspaceRevision {
            id: gen_workspace_id(),
            name: params.name,
            desc: params.desc,
            apps: vec![],
            modified_time: time,
            create_time: time,
        };

        FutureResult::new(async { Ok(workspace) })
    }

    fn read_workspace(&self, _token: &str, _params: WorkspaceIdPB) -> FutureResult<Vec<WorkspaceRevision>, FlowyError> {
        FutureResult::new(async { Ok(vec![]) })
    }

    fn update_workspace(&self, _token: &str, _params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_workspace(&self, _token: &str, _params: WorkspaceIdPB) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_view(&self, _token: &str, params: CreateViewParams) -> FutureResult<ViewRevision, FlowyError> {
        let time = timestamp();
        let view = ViewRevision {
            id: params.view_id,
            app_id: params.belong_to_id,
            name: params.name,
            desc: params.desc,
            data_format: params.data_format.into(),
            version: 0,
            belongings: vec![],
            modified_time: time,
            create_time: time,
            ext_data: "".to_string(),
            thumbnail: params.thumbnail,
            layout: params.layout.into(),
        };
        FutureResult::new(async { Ok(view) })
    }

    fn read_view(&self, _token: &str, _params: ViewIdPB) -> FutureResult<Option<ViewRevision>, FlowyError> {
        FutureResult::new(async { Ok(None) })
    }

    fn delete_view(&self, _token: &str, _params: RepeatedViewIdPB) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn update_view(&self, _token: &str, _params: UpdateViewParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_app(&self, _token: &str, params: CreateAppParams) -> FutureResult<AppRevision, FlowyError> {
        let time = timestamp();
        let app = AppRevision {
            id: gen_app_id(),
            workspace_id: params.workspace_id,
            name: params.name,
            desc: params.desc,
            belongings: vec![],
            version: 0,
            modified_time: time,
            create_time: time,
        };
        FutureResult::new(async { Ok(app) })
    }

    fn read_app(&self, _token: &str, _params: AppIdPB) -> FutureResult<Option<AppRevision>, FlowyError> {
        FutureResult::new(async { Ok(None) })
    }

    fn update_app(&self, _token: &str, _params: UpdateAppParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_app(&self, _token: &str, _params: AppIdPB) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_trash(&self, _token: &str, _params: RepeatedTrashIdPB) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_trash(&self, _token: &str, _params: RepeatedTrashIdPB) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn read_trash(&self, _token: &str) -> FutureResult<Vec<TrashRevision>, FlowyError> {
        FutureResult::new(async { Ok(vec![]) })
    }
}

impl UserCloudService for LocalServer {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
        let uid = nanoid!(20);
        FutureResult::new(async move {
            Ok(SignUpResponse {
                user_id: uid.clone(),
                name: params.name,
                email: params.email,
                token: uid,
            })
        })
    }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
        let user_id = nanoid!(20);
        FutureResult::new(async {
            Ok(SignInResponse {
                user_id: user_id.clone(),
                name: params.name,
                email: params.email,
                token: user_id,
            })
        })
    }

    fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn update_user(&self, _token: &str, _params: UpdateUserProfileParams) -> FutureResult<(), FlowyError> {
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
    fn create_document(&self, _token: &str, _params: CreateDocumentParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn fetch_document(&self, _token: &str, _params: DocumentId) -> FutureResult<Option<DocumentPayload>, FlowyError> {
        FutureResult::new(async { Ok(None) })
    }

    fn update_document_content(&self, _token: &str, _params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }
}
