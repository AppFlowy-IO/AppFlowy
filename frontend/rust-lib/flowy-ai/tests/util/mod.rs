use flowy_ai::config::OpenAISetting;

// To run the OpenAI test, you need to create a .env file in the flowy-ai folder.
// Use the format: OPENAI_API_KEY=your_api_key
#[allow(dead_code)]
pub fn get_openai_config() -> Option<OpenAISetting> {
  dotenv::from_filename(".env").ok()?;
  OpenAISetting::from_env().ok()
}
