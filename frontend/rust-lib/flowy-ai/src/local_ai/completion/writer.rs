use crate::local_ai::completion::chain::CompletionWriter;
use flowy_ai_pub::cloud::CustomPrompt;

pub struct CompletionWriterContext {
  custom_system_reasoning_prompt: Option<String>,
}

impl CompletionWriterContext {
  pub fn new(custom_system_reasoning_prompt: Option<String>) -> Self {
    CompletionWriterContext {
      custom_system_reasoning_prompt,
    }
  }
}

// ImproveWritingWriter implementation
pub struct ImproveWritingWriter {
  context: CompletionWriterContext,
}

impl ImproveWritingWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    ImproveWritingWriter { context }
  }
}

impl CompletionWriter for ImproveWritingWriter {
  fn system_message(&self) -> String {
    r#"You are an expert in refining written material, making it engaging, clear, and effective.
Ensure that your final output maintains the same format and language as the human input."#
      .to_string()
  }

  fn reasoning_system_message(&self) -> String {
    if let Some(prompt) = &self.context.custom_system_reasoning_prompt {
      return prompt.clone();
    }

    r#"You are an expert writing coach specializing in making text more engaging, clear, and impactful 
while preserving the original meaning and intent. Your task is to thoughtfully enhance any text I submit.

1. Provide an improved version of the text
2. Explain what was enhanced:
   - Identify specific areas of improvement (clarity, conciseness, word choice, etc.)
   - Use markdown formatting (**bold** or `code`) to highlight modified sections
   - If the text already appears optimal, acknowledge its strengths and return it unchanged
3.Maintain the original tone, style, and level of formality
4. Preserve the author's unique voice and perspective
5. Keep specialized terminology and technical language intact
6. Focus on enhancing readability and impact without changing the core message

Format your response like this:
<Improved>[The enhanced version of the text]</Improved>
<Explanation>[Detailed explanation of each improvement made, with before/after comparisons highlighted]</Explanation>

Example:
<Improved>Original text with improvements</Improved>
<Explanation>Original text with explanations of improvements</Explanation>
"#.to_string()
  }

  fn support_format(&self) -> bool {
    false
  }

  fn support_reasoning(&self) -> bool {
    true
  }
}

// SpellingGrammarWriter implementation
pub struct SpellingGrammarWriter {
  context: CompletionWriterContext,
}

impl SpellingGrammarWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    SpellingGrammarWriter { context }
  }
}

impl CompletionWriter for SpellingGrammarWriter {
  fn system_message(&self) -> String {
    r#"You excel at identifying and correcting grammatical and spelling errors, ensuring accuracy and professionalism in the text. Provide only the final corrected version without additional commentary, and ensure that your final output maintains the same format and language as the user input."#.to_string()
  }

  fn reasoning_system_message(&self) -> String {
    if let Some(prompt) = &self.context.custom_system_reasoning_prompt {
      return prompt.clone();
    }

    r#"You excel at identifying and correcting grammatical and spelling errors while maintaining the original text's meaning and style. Your task is to provide corrections and explanations for any text I submit.
For each submission, please:

1. Provide the corrected version of the text
2. Explain the corrections made:
   - Identify specific grammatical and spelling issues
   - Use markdown formatting (**bold** or `code`) to highlight problem areas
   - If no errors exist, simply confirm the text is correct
3. Preserve the original format, style, and language

Format your response like this:
<Corrected>[The fully corrected text]</Corrected>
<Explanation>[Clear explanation of each correction made, with examples highlighted]</Explanation>

Example:
<Corrected>Original text with corrections</Corrected>
<Explanation>Original text with explanations of corrections</Explanation>

"#.to_string()
  }

  fn support_format(&self) -> bool {
    false
  }

  fn support_reasoning(&self) -> bool {
    true
  }
}

// SummaryWriter implementation
pub struct SummaryWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
}

impl SummaryWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    SummaryWriter { context }
  }
}

impl CompletionWriter for SummaryWriter {
  fn system_message(&self) -> String {
    r#"You are skilled at summarizing text, capturing its core message in a concise, clear manner without losing its original intent. Ensure that your final output retains the same format and language as the user input."#.to_string()
  }

  fn support_format(&self) -> bool {
    true
  }
}

// MakeLongerWriter implementation
pub struct MakeLongerWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
}

impl MakeLongerWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    MakeLongerWriter { context }
  }
}

impl CompletionWriter for MakeLongerWriter {
  fn system_message(&self) -> String {
    r#"You are skilled at expanding and elaborating on existing content, enriching it with additional details while maintaining the original meaning. Ensure that your final output maintains the same format and language as the user input."#.to_string()
  }

  fn support_format(&self) -> bool {
    true
  }
}

// ContinueWriteWriter implementation
pub struct ContinueWriteWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
}

impl ContinueWriteWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    ContinueWriteWriter { context }
  }
}

impl CompletionWriter for ContinueWriteWriter {
  fn system_message(&self) -> String {
    r#"You are the AppFlowyAI writing assistant. Treat the user's latest input as the foundational context.
Analyze its themes, style, tone, and key ideas, then extend the content with new, relevant details and 
logical elaborations, ensuring coherence and consistency. Ensure that your final output maintains the 
same format and language as the user input."#
      .to_string()
  }

  fn support_format(&self) -> bool {
    true
  }
}

// ExplainWriter implementation
pub struct ExplainWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
}

impl ExplainWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    ExplainWriter { context }
  }
}

impl CompletionWriter for ExplainWriter {
  fn system_message(&self) -> String {
    r#"You are an expert educator and communicator who excels at making complex ideas accessible. Your task is 
to analyze and explain any concept or text I share with you.
When I provide text, please:

1. Identify the core concept, idea, or message
2. Break it down into clear, digestible components
3. Provide a comprehensive yet concise explanation
4. Include relevant examples, analogies, or illustrations that clarify the concept
5. Match your explanation to my level of understanding based on my query
6. Respond in the same language as my input

Your explanation should:
- Be easy to understand without oversimplifying
- Highlight key themes and important details
- Connect the concept to broader knowledge when helpful
- Be organized in a logical progression
- Preserve the nuance and depth of the original idea

Focus on delivering a thoughtful explanation that would help someone truly grasp the concept rather than 
just rephrasing the input."#
      .to_string()
  }

  fn support_format(&self) -> bool {
    true
  }
}

// AskAiWriter implementation
pub struct AskAiWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
}

impl AskAiWriter {
  pub fn new(context: CompletionWriterContext) -> Self {
    AskAiWriter { context }
  }
}

impl CompletionWriter for AskAiWriter {
  fn system_message(&self) -> String {
    r#"You are AppFlowy AI, adept at understanding and answering user inquiries quickly and accurately.
Provide clear, concise responses that effectively resolve the query, and ensure your final output is in the 
same language as the user input."#
      .to_string()
  }

  fn support_format(&self) -> bool {
    true
  }
}

// CustomWriter implementation for user-provided prompts
pub struct CustomWriter {
  #[allow(dead_code)]
  context: CompletionWriterContext,
  prompt: CustomPrompt,
}

impl CustomWriter {
  pub fn new(prompt: CustomPrompt, context: CompletionWriterContext) -> Self {
    CustomWriter { context, prompt }
  }
}

impl CompletionWriter for CustomWriter {
  fn system_message(&self) -> String {
    self.prompt.system.clone()
  }

  fn support_format(&self) -> bool {
    true
  }
}
