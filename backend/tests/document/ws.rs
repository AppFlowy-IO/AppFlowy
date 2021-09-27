use crate::document::helper::{DocScript, DocumentTest};
use tokio::time::{interval, Duration};

#[actix_rt::test]
async fn ws_connect() {
    let test = DocumentTest::new().await;
    test.run_scripts(vec![DocScript::SendText("abc")]).await;

    let mut interval = interval(Duration::from_secs(10));
    interval.tick().await;
    interval.tick().await;
}
