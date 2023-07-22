use flowy_ai::send_request;

#[tokio::main]
async fn main() {
  match send_request().await {
    Ok(response) => println!("Response: {}", response),
    Err(e) => eprintln!("Error: {}", e),
  }
}
