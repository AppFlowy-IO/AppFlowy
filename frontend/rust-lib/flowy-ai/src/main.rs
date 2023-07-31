use flowy_ai::send_request;

#[tokio::main]
async fn main() {
  let content_type = "blog post"; // replace this with actual user input
  let topic = "Plan a trip to Paris"; // replace this with actual user input
  let prompt = format!("Write a {} about {}", content_type, topic);
  match send_request(prompt).await {
    Ok(response) => println!("Response: {}", response),
    Err(e) => eprintln!("Error: {}", e),
  }
}
