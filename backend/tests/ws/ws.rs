use crate::ws::helper::{WsScript, WsTest};

#[actix_rt::test]
async fn ws_connect() {
    let mut ws = WsTest::new(vec![
        WsScript::SendText("abc"),
        WsScript::SendText("abc"),
        WsScript::SendText("abc"),
        WsScript::Disconnect("close by user"),
    ])
    .await;
    ws.run_scripts().await
}
