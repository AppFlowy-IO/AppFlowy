use flowy_test::editor::*;

#[tokio::test]
async fn create_doc() {
    let test = EditorTest::new().await;
    let _editor = test.create_doc().await;
    println!("123");
}
