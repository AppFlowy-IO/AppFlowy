use backend_service::configuration::ClientServerConfiguration;
use bytes::Bytes;
use flowy_collaboration::entities::{
    doc::{CreateDocParams, DocumentId, DocumentInfo, ResetDocumentParams},
    ws::DocumentClientWSData,
};
use flowy_database::ConnectionPool;
use flowy_document::{
    context::DocumentUser,
    core::{DocumentWSReceivers, DocumentWebSocket, WSStateReceiver},
    errors::{internal_error, FlowyError},
    DocumentCloudService,
};
use flowy_net::{
    cloud::document::{DocumentHttpCloudService, DocumentLocalCloudService},
    ws::connection::FlowyWebSocketConnect,
};
use flowy_user::services::UserSession;
use lib_infra::future::FutureResult;
use lib_ws::{WSMessageReceiver, WSModule, WebSocketRawMessage};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDependencies {
    pub user: Arc<dyn DocumentUser>,
    pub ws_receivers: Arc<DocumentWSReceivers>,
    pub ws_sender: Arc<dyn DocumentWebSocket>,
    pub cloud_service: Arc<dyn DocumentCloudService>,
}

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
    pub fn resolve(
        ws_conn: Arc<FlowyWebSocketConnect>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
    ) -> DocumentDependencies {
        let user = Arc::new(DocumentUserImpl(user_session));
        let ws_sender = Arc::new(DocumentWebSocketImpl(ws_conn.clone()));
        let ws_receivers = Arc::new(DocumentWSReceivers::new());
        let receiver = Arc::new(WSMessageReceiverImpl(ws_receivers.clone()));
        ws_conn.add_ws_message_receiver(receiver).unwrap();
        let cloud_service = make_document_cloud_service(server_config);
        DocumentDependencies {
            user,
            ws_receivers,
            ws_sender,
            cloud_service,
        }
    }
}

struct DocumentUserImpl(Arc<UserSession>);
impl DocumentUser for DocumentUserImpl {
    fn user_dir(&self) -> Result<String, FlowyError> {
        let dir = self.0.user_dir().map_err(|e| FlowyError::unauthorized().context(e))?;

        let doc_dir = format!("{}/document", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, FlowyError> { self.0.user_id() }

    fn token(&self) -> Result<String, FlowyError> { self.0.token() }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> { self.0.db_pool() }
}

struct DocumentWebSocketImpl(Arc<FlowyWebSocketConnect>);
impl DocumentWebSocket for DocumentWebSocketImpl {
    fn send(&self, data: DocumentClientWSData) -> Result<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            module: WSModule::Doc,
            data: bytes.to_vec(),
        };
        let sender = self.0.ws_sender()?;
        sender.send(msg).map_err(internal_error)?;
        Ok(())
    }

    fn subscribe_state_changed(&self) -> WSStateReceiver { self.0.subscribe_websocket_state() }
}

struct WSMessageReceiverImpl(Arc<DocumentWSReceivers>);
impl WSMessageReceiver for WSMessageReceiverImpl {
    fn source(&self) -> WSModule { WSModule::Doc }
    fn receive_message(&self, msg: WebSocketRawMessage) {
        let receivers = self.0.clone();
        tokio::spawn(async move {
            receivers.did_receive_data(Bytes::from(msg.data)).await;
        });
    }
}

fn make_document_cloud_service(server_config: &ClientServerConfiguration) -> Arc<dyn DocumentCloudService> {
    if cfg!(feature = "http_server") {
        Arc::new(DocumentHttpCloudServiceAdaptor::new(server_config.clone()))
    } else {
        Arc::new(DocumentLocalCloudServiceAdaptor::new())
    }
}

struct DocumentHttpCloudServiceAdaptor(DocumentHttpCloudService);
impl DocumentHttpCloudServiceAdaptor {
    fn new(config: ClientServerConfiguration) -> Self {
        DocumentHttpCloudServiceAdaptor(DocumentHttpCloudService::new(config))
    }
}
impl DocumentCloudService for DocumentHttpCloudServiceAdaptor {
    fn create_document(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError> {
        self.0.create_document_request(token, params)
    }

    fn read_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentInfo>, FlowyError> {
        self.0.read_document_request(token, params)
    }

    fn update_document(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        self.0.update_document_request(token, params)
    }
}

struct DocumentLocalCloudServiceAdaptor(DocumentLocalCloudService);
impl DocumentLocalCloudServiceAdaptor {
    fn new() -> Self { Self(DocumentLocalCloudService {}) }
}
impl DocumentCloudService for DocumentLocalCloudServiceAdaptor {
    fn create_document(&self, token: &str, params: CreateDocParams) -> FutureResult<(), FlowyError> {
        self.0.create_document_request(token, params)
    }

    fn read_document(&self, token: &str, params: DocumentId) -> FutureResult<Option<DocumentInfo>, FlowyError> {
        self.0.read_document_request(token, params)
    }

    fn update_document(&self, token: &str, params: ResetDocumentParams) -> FutureResult<(), FlowyError> {
        self.0.update_document_request(token, params)
    }
}
