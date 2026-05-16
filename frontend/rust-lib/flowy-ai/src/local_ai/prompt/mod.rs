use flowy_ai_pub::cloud::{CompletionMessage, OutputLayout, ResponseFormat};
use langchain_rust::schemas::{Message, MessageType};

pub const OPEN_AI_QA_FLEX_FORMAT: &str = r#"Use Markdown for formatting. Start responses naturally—avoid formal phrases like “Certainly,” “Absolutely,” or “Sure.” Keep the tone conversational, clear, and professional."#;

const OPEN_AI_QA_PARAGRAPH_FORMAT: &str = r#"Respond naturally in one paragraph. Avoid formal phrases like “Certainly,” “Absolutely,” or “Sure.” Keep the tone conversational, clear, and professional."#;

const OPEN_AI_QA_BULLET_LIST_FORMAT: &str = r#"Organize the provided information into a natural, practical, and well-structured response using a bullet list format. Follow these guidelines:
1. Begin your response with a brief description of the content.
2. Use `*` to denote each bullet point and ensure each point is clear, informative, and relevant.
3. Avoid overly formal language. Present information in a tone and style that people commonly use in discussions or comparisons.
4. Ensure the response is well-structured without unnecessary spaces or formatting issues.
5. Optional Context: Include a brief description or context (1–2 sentences) at the end, if necessary, to summarize or provide additional insights."#;

const OPEN_AI_QA_NUMBER_LIST_FORMAT: &str = r#"Organize the provided information into a natural, practical, and well-structured response using a numbered list format. Follow these guidelines:
1. Begin your response with a brief description of the content.
2. Use numbers (e.g., 1., 2., 3.) to denote each point and ensure they are clear, sequential, and easy to understand.
3. Avoid overly formal language. Present information in a tone and style that people commonly use in discussions or comparisons.
4. Avoid adding unnecessary spaces or formatting issues.
5. Optional Context: Include a brief description or context (1–2 sentences) at the end, if necessary, to summarize or provide additional insights."#;

const OPEN_AI_QA_SIMPLE_TABLE_FORMAT: &str = r#"Organize the provided information into a natural, practical, and well-structured table using Markdown format. Follow these guidelines:
1. Purpose and Clarity: Ensure the table is designed to be useful and relatable for the intended audience (e.g., developers, team members, or general readers).
2. Structure: Use concise headers and rows that highlight the most relevant details without unnecessary complexity.
3. Natural Style: Avoid overly formal language. Present information in a tone and style that people commonly use in discussions or comparisons.
4. Readability: Keep the table visually clean, with evenly spaced columns and clear separation between rows.
5. Optional Context: Include a brief description or context (1–2 sentences) before or after the table to summarize its purpose or provide additional insights.

Example:
input: Iconic Singapore Landmarks
output:
Singapore’s landmarks blend modern architecture with natural beauty. Here’s an overview of its most iconic attractions:
| Attraction         | Description                                         |
|--------------------|-----------------------------------------------------|
| Marina Bay Sands   | Iconic resort with a rooftop infinity pool.         |
| Gardens by the Bay | Futuristic nature park featuring Supertree Grove.   |
| Merlion Park       | Home to the iconic Merlion statue.                  |
| Sentosa Island     | Beaches, theme parks, and Universal Studios Singapore. |

These attractions highlight Singapore’s blend of modernity and greenery, offering visitors diverse experiences."#;

pub fn format_prompt(format: &ResponseFormat) -> Message {
  match format.output_layout {
    OutputLayout::Paragraph => Message::new_system_message(OPEN_AI_QA_PARAGRAPH_FORMAT),
    OutputLayout::BulletList => Message::new_system_message(OPEN_AI_QA_BULLET_LIST_FORMAT),
    OutputLayout::NumberedList => Message::new_system_message(OPEN_AI_QA_NUMBER_LIST_FORMAT),
    OutputLayout::SimpleTable => Message::new_system_message(OPEN_AI_QA_SIMPLE_TABLE_FORMAT),
    OutputLayout::Flex => Message::new_system_message(OPEN_AI_QA_FLEX_FORMAT),
  }
}

pub fn history_prompt(history: Option<Vec<CompletionMessage>>) -> Vec<Message> {
  let mut messages = vec![];
  if let Some(history) = history {
    for message in history {
      if let Ok(message_type) = serde_json::from_str::<MessageType>(&message.role) {
        messages.push(Message {
          content: message.content,
          message_type,
          id: None,
          tool_calls: None,
          images: None,
        });
      }
    }
  }

  if !messages.is_empty() {
    let content = r#"
      Analyze the conversation history to identify the core question or request in the user's most recent message.
Then:
1. Silently reframe the complete question in your mind
2. Deliver your answer directly without introductory phrases such as "Here is", "Certainly", "Here's the translation", etc.
3. Maintain the established conversation tone while providing thorough information
4. Begin your response immediately with the relevant content the user is seeking
Provide precise, helpful answers without meta-commentary about your interpretation process or unnecessary lead-in phrases.
      "#;
    messages.insert(0, Message::new_system_message(content));
  }
  messages
}
