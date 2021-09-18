use crate::helper::TestServer;
use flowy_ws::WsController;

#[actix_rt::test]
async fn ws_connect() {
    let server = TestServer::new().await;
    let mut controller = WsController::new();
    let addr = server.ws_addr();
    let _ = controller.connect(addr).unwrap().await;
}
