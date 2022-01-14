use crate::{
    context::FlowyPersistence,
    services::{
        folder::ws_actor::{FolderWSActorMessage, FolderWebSocketActor},
        web_socket::{WSClientData, WebSocketReceiver},
    },
};

use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub fn make_folder_ws_receiver(persistence: Arc<FlowyPersistence>) -> Arc<FolderWebSocketReceiver> {
    let (ws_sender, rx) = tokio::sync::mpsc::channel(1000);
    let actor = FolderWebSocketActor::new(rx);
    tokio::task::spawn(actor.run());
    Arc::new(FolderWebSocketReceiver::new(persistence, ws_sender))
}

pub struct FolderWebSocketReceiver {
    ws_sender: mpsc::Sender<FolderWSActorMessage>,
    persistence: Arc<FlowyPersistence>,
}

impl FolderWebSocketReceiver {
    pub fn new(persistence: Arc<FlowyPersistence>, ws_sender: mpsc::Sender<FolderWSActorMessage>) -> Self {
        Self { ws_sender, persistence }
    }
}

impl WebSocketReceiver for FolderWebSocketReceiver {
    fn receive(&self, data: WSClientData) {
        let (ret, rx) = oneshot::channel();
        let sender = self.ws_sender.clone();
        let persistence = self.persistence.clone();

        actix_rt::spawn(async move {
            let msg = FolderWSActorMessage::ClientData {
                client_data: data,
                persistence,
                ret,
            };

            match sender.send(msg).await {
                Ok(_) => {},
                Err(e) => log::error!("{}", e),
            }
            match rx.await {
                Ok(_) => {},
                Err(e) => log::error!("{:?}", e),
            };
        });
    }
}
