use crate::helper::TestServer;
use flowy_ws::{WsController, WsModule, WsSender, WsState};
use parking_lot::RwLock;
use std::sync::Arc;

pub struct WsTest {
    server: TestServer,
    ws_controller: Arc<RwLock<WsController>>,
}

#[derive(Clone)]
pub enum WsScript {
    SendText(&'static str),
    SendBinary(Vec<u8>),
    Disconnect(&'static str),
}

impl WsTest {
    pub async fn new(scripts: Vec<WsScript>) -> Self {
        let server = TestServer::new().await;
        let ws_controller = Arc::new(RwLock::new(WsController::new()));
        ws_controller
            .write()
            .state_callback(move |state| match state {
                WsState::Connected(sender) => {
                    WsScriptRunner {
                        scripts: scripts.clone(),
                        sender: sender.clone(),
                        source: WsModule::Doc,
                    }
                    .run();
                },
                _ => {},
            })
            .await;

        Self {
            server,
            ws_controller,
        }
    }

    pub async fn run_scripts(&mut self) {
        let addr = self.server.ws_addr();
        self.ws_controller
            .write()
            .connect(addr)
            .unwrap()
            .await
            .unwrap();
    }
}

struct WsScriptRunner {
    scripts: Vec<WsScript>,
    sender: Arc<WsSender>,
    source: WsModule,
}

impl WsScriptRunner {
    fn run(self) {
        for script in self.scripts {
            match script {
                WsScript::SendText(text) => {
                    self.sender.send_text(&self.source, text).unwrap();
                },
                WsScript::SendBinary(bytes) => {
                    self.sender.send_binary(&self.source, bytes).unwrap();
                },
                WsScript::Disconnect(reason) => {
                    self.sender.send_disconnect(reason).unwrap();
                },
            }
        }
    }
}
