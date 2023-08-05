// main.rs
use flowy_ai::api::send_request;
use flowy_ai::prompt::PromptBuilder;

#[tokio::main]
async fn main() {
  let prompt = PromptBuilder::new()
    .content_type("blog post".to_string())
    .topic("Plan a trip to Paris".to_string())
    .build()
    .unwrap()
    .format();

  match send_request(prompt).await {
    Ok(response) => println!("Response: {}", response),
    Err(e) => eprintln!("Error: {}", e),
  }
}
