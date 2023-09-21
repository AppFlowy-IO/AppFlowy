use anyhow::{anyhow, Error};

pub struct OpenAISetting {
  pub openai_api_key: String,
}

const OPENAI_API_KEY: &str = "OPENAI_API_KEY";

impl OpenAISetting {
  pub fn from_env() -> Result<Self, Error> {
    let openai_api_key =
      std::env::var(OPENAI_API_KEY).map_err(|_| anyhow!("Missing OPENAI_API_KEY"))?;

    Ok(Self { openai_api_key })
  }
}
