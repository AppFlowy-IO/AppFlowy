// prompt.rs
pub struct Prompt {
  content_type: String,
  topic: String,
}

impl Prompt {
  pub fn new(content_type: String, topic: String) -> Self {
    Self {
      content_type,
      topic,
    }
  }

  pub fn format(&self) -> String {
    format!("Write a {} about {}", self.content_type, self.topic)
  }

  // Add getter methods
  pub fn content_type(&self) -> &String {
    &self.content_type
  }

  pub fn topic(&self) -> &String {
    &self.topic
  }
}

pub struct PromptBuilder {
  content_type: Option<String>,
  topic: Option<String>,
}

impl PromptBuilder {
  pub fn new() -> Self {
    Self {
      content_type: None,
      topic: None,
    }
  }

  pub fn content_type(mut self, content_type: String) -> Self {
    self.content_type = Some(content_type);
    self
  }

  pub fn topic(mut self, topic: String) -> Self {
    self.topic = Some(topic);
    self
  }

  pub fn build(self) -> Result<Prompt, &'static str> {
    let content_type = self.content_type.ok_or("Content type is missing")?;
    let topic = self.topic.ok_or("Topic is missing")?;
    Ok(Prompt::new(content_type, topic))
  }
}
