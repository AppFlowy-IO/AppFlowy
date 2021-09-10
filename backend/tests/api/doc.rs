use crate::helper::DocTest;

#[actix_rt::test]
async fn doc_create() {
    let test = DocTest::new().await;

    log::info!("{:?}", test.doc);
}
