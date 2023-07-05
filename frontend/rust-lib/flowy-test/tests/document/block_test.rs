use flowy_test::document::text_block_event::TextBlockEventTest;
use flowy_test::document::utils::gen_text_block_data;

#[tokio::test]
async fn insert_text_block_test() {
  let test = TextBlockEventTest::new().await;
  let text = "Hello World".to_string();
  let block_id = test.insert_index(text.clone(), 1, None).await;
  let block = test.get(&block_id).await;
  assert!(block.is_some());
  let block = block.unwrap();
  let data = gen_text_block_data(text);
  assert_eq!(block.data, data);
}

#[tokio::test]
async fn update_text_block_test() {
  let test = TextBlockEventTest::new().await;
  let insert_text = "Hello World".to_string();
  let block_id = test.insert_index(insert_text.clone(), 1, None).await;
  let update_text = "Hello World 2".to_string();
  test.update(&block_id, update_text.clone()).await;
  let block = test.get(&block_id).await;
  assert!(block.is_some());
  let block = block.unwrap();
  let update_data = gen_text_block_data(update_text);
  assert_eq!(block.data, update_data);
}
