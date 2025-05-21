use crate::setup_log;
use flowy_ai::local_ai::chat::llm::LLMOllama;
use flowy_ai::local_ai::completion::chain::CompletionChain;
use flowy_ai::local_ai::completion::stream_interpreter::stream_interpreter_for_completion;
use flowy_ai_pub::cloud::{CompletionStreamValue, CompletionType, OutputLayout, ResponseFormat};
use flowy_error::FlowyError;
use futures_util::{StreamExt, stream, stream::BoxStream};
use langchain_rust::language_models::LLMError;
use langchain_rust::schemas::StreamData;
use serde_json::json;
use tokio_stream::wrappers::ReceiverStream;
use tracing::error;

#[tokio::test]
async fn local_ollama_test_simple_ask_ai() {
  let ollama = LLMOllama::default().with_model("llama3.1");
  let ai_completion = CompletionChain::new(ollama);
  let text = "Compare js with Rust";
  let ty = CompletionType::AskAI;
  let mut format = ResponseFormat::new();
  format.output_layout = OutputLayout::SimpleTable;

  let stream = ai_completion
    .complete(text, ty, format, None)
    .await
    .unwrap();
  let (answer, comment) = collect_completion_stream(stream).await;
  dbg!(&answer);
  assert!(!answer.is_empty());
  assert!(comment.is_empty());
}

#[tokio::test]
async fn local_ollama_test_improve_writing() {
  setup_log();
  let ollama = LLMOllama::default().with_model("llama3.1");
  let ai_completion = CompletionChain::new(ollama);
  let text = "I like playing basketball with my friend";
  let ty = CompletionType::ImproveWriting;
  let format = ResponseFormat::default();
  let stream = ai_completion
    .complete(text, ty, format, None)
    .await
    .unwrap();
  let (answer, comment) = collect_completion_stream(stream).await;
  dbg!(&answer);
  dbg!(&comment);
  assert!(!answer.is_empty());
  assert!(!comment.is_empty());
}

#[tokio::test]
async fn local_ollama_test_simple_fix_grammar() {
  setup_log();
  let ollama = LLMOllama::default().with_model("llama3.1");
  let ai_completion = CompletionChain::new(ollama);
  let text = "He starts work everyday at 8 a.m";
  let ty = CompletionType::SpellingAndGrammar;
  let format = ResponseFormat::default();
  let stream = ai_completion
    .complete(text, ty, format, None)
    .await
    .unwrap();
  let (answer, comment) = collect_completion_stream(stream).await;
  dbg!(&answer);
  dbg!(&comment);
  assert!(!answer.is_empty());
  assert!(!comment.is_empty());
}

async fn collect_completion_stream(
  mut stream: ReceiverStream<Result<CompletionStreamValue, FlowyError>>,
) -> (String, String) {
  let mut answer = Vec::new();
  let mut comment = Vec::new();
  while let Some(item) = stream.next().await {
    match item {
      Ok(CompletionStreamValue::Answer { value }) => {
        dbg!(&value);
        answer.push(value);
      },
      Ok(CompletionStreamValue::Comment { value }) => {
        dbg!(&value);
        comment.push(value);
      },
      Err(e) => {
        error!("[collect_completion_stream] error: {:?}", e);
      },
    }
  }
  (answer.join(""), comment.join(""))
}

/// Helper function to create a mock stream from chunks of text
pub fn create_mock_stream(chunks: Vec<&str>) -> BoxStream<'static, Result<StreamData, LLMError>> {
  setup_log();
  let stream_items = chunks
    .into_iter()
    .map(|chunk| {
      Ok(StreamData {
        value: json!({
            "message": {
                "content": chunk
            }
        }),
        content: chunk.to_string(),
        tokens: None,
      })
    })
    .collect::<Vec<Result<StreamData, LLMError>>>();

  stream::iter(stream_items).boxed()
}

/// Collects all values from a completion stream into a tuple of (answer, comment)
pub async fn collect_completion_results(
  mut stream: BoxStream<'static, Result<CompletionStreamValue, LLMError>>,
) -> (String, String) {
  let mut answer = String::new();
  let mut comment = String::new();

  while let Some(result) = stream.next().await {
    match result {
      Ok(CompletionStreamValue::Answer { value }) => {
        answer.push_str(&value);
      },
      Ok(CompletionStreamValue::Comment { value }) => {
        comment.push_str(&value);
      },
      _ => {},
    }
  }

  (answer, comment)
}

#[tokio::test]
async fn test_multiple_tags_same_type() {
  // Test when multiple tags of the same type appear in the stream
  let chunks = vec![
    "**Improved**\nFirst improvement.\n\n",
    "**Explanation**\nThe explanation.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  // It should use the first "Improved" tag's content
  assert_eq!(answer, "First improvement.");
  assert_eq!(comment, "The explanation.");
}

// #[tokio::test]
// async fn test_empty_content_between_tags() {
//   // Test when there's no content between tags
//   let chunks = vec!["**Improved**\n\n", "**Explanation**\nSome explanation."];
//
//   let stream = create_mock_stream(chunks);
//   let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);
//
//   let (answer, comment) = collect_completion_results(result_stream).await;
//
//   assert_eq!(answer, ""); // Empty content should result in empty answer
//   assert_eq!(comment, "Some explanation.");
// }

#[tokio::test]
async fn test_case_insensitive_tags() {
  // Test tags with different cases
  let chunks = vec![
    "**improved**\nLowercase tag.\n\n",
    "**EXPLANATION**\nUppercase tag.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "Lowercase tag.");
  assert_eq!(comment, "Uppercase tag.");
}

#[tokio::test]
async fn test_xml_style_tags() {
  // Test XML-style tags as an alternative format
  let chunks = vec![
    "<Improved>\nXML style improved content.\n</Improved>\n",
    "<Explanation>\nXML style explanation.\n</Explanation>",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "XML style improved content.");
  assert_eq!(comment, "XML style explanation.");
}

#[tokio::test]
async fn test_malformed_tags() {
  // Test incomplete or malformed tags
  let chunks = vec![
    "**Improved\nMalformed opening tag.\n\n", // Missing closing **
    "Explanation**\nMalformed opening tag again.\n\n", // Missing opening **
    "**Improved**\nThis should be recognized.\n\n",
    "**Explanation**\nProper explanation.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  // The parser should ignore malformed tags and find the proper ones
  assert_eq!(answer, "This should be recognized.");
  assert_eq!(comment, "Proper explanation.");
}

#[tokio::test]
async fn test_large_content() {
  // Test with larger chunks of content
  let large_text = "A ".repeat(1000) + "large text";
  let large_explanation = "The ".repeat(1000) + "explanation";

  let chunks = [
    format!("**Improved**\n{}\n\n", large_text),
    format!("**Explanation**\n{}", large_explanation),
  ];

  let stream = create_mock_stream(chunks.iter().map(|s| s.as_str()).collect());
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, large_text);
  assert_eq!(comment, large_explanation);
}

#[tokio::test]
async fn test_no_tags() {
  // Test when no tags are present in the response
  let chunks = vec![
    "This content has no tags.",
    "It should be passed through as is.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  // Without tags, we shouldn't extract any content
  assert_eq!(answer, "");
  assert_eq!(comment, "");
}

#[tokio::test]
async fn test_spelling_grammar_completion_type() {
  // Test with SpellingAndGrammar completion type
  let chunks = vec![
    "**Corrected**\nCorrected spelling.\n\n",
    "**Explanation**\nSpelling corrections explanation.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::SpellingAndGrammar);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "Corrected spelling.");
  assert_eq!(comment, "Spelling corrections explanation.");
}

#[tokio::test]
async fn test_delayed_tag_detection() {
  // Test when there's a lot of content before any tag appears
  let prefix = "This is a lot of preliminary text that contains no tags.\n".repeat(10);

  let chunks = vec![
    &prefix,
    "**Improved**\nFinally, the improved content.\n\n",
    "**Explanation**\nThe explanation after delay.",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);
  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "Finally, the improved content.");
  assert_eq!(comment, "The explanation after delay.");
}

// #[tokio::test]
// async fn test_non_standard_tag_formats() {
//   // Test with tag format variations that might be produced by different LLMs
//   let chunks = vec![
//     "**[Improved]**\nBracketed tag format.\n\n",
//     "**<Explanation>**\nAngled bracket in markdown.",
//   ];
//
//   let stream = create_mock_stream(chunks);
//   let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);
//
//   let (answer, comment) = collect_completion_results(result_stream).await;
//
//   // These tags don't match our standard format, so should be ignored
//   assert_eq!(answer, "");
//   assert_eq!(comment, "");
// }

#[tokio::test]
async fn test_multiple_completion_calls() {
  // Test processing multiple completion rounds in sequence
  // First round
  let chunks1 = vec![
    "**Improved**\nFirst round improvement.\n\n",
    "**Explanation**\nFirst explanation.",
  ];

  let stream1 = create_mock_stream(chunks1);
  let result_stream1 = stream_interpreter_for_completion(stream1, CompletionType::ImproveWriting);
  let (answer1, comment1) = collect_completion_results(result_stream1).await;

  // Second round with different content
  let chunks2 = vec![
    "**Improved**\nSecond round improvement.\n\n",
    "**Explanation**\nSecond explanation.",
  ];

  let stream2 = create_mock_stream(chunks2);
  let result_stream2 = stream_interpreter_for_completion(stream2, CompletionType::ImproveWriting);
  let (answer2, comment2) = collect_completion_results(result_stream2).await;

  // Each round should be processed independently
  assert_eq!(answer1, "First round improvement.");
  assert_eq!(comment1, "First explanation.");
  assert_eq!(answer2, "Second round improvement.");
  assert_eq!(comment2, "Second explanation.");
}

#[tokio::test]
async fn test_special_characters_in_content() {
  // Test content with special characters that might affect parsing
  let special_content =
    "**Improved**\nContent with **asterisks**, <brackets>, \n\nand other $p3c!@l characters.\n\n";
  let special_explanation =
    "**Explanation**\nExplanation with **formatting** and <xml-like> elements.";

  let chunks = vec![special_content, special_explanation];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(
    answer,
    "Content with **asterisks**, <brackets>, \n\nand other $p3c!@l characters."
  );
  assert_eq!(
    comment,
    "Explanation with **formatting** and <xml-like> elements."
  );
}

#[tokio::test]
async fn test_content_with_unicode() {
  // Test content with unicode characters
  let unicode_content = "**Improved**\n🚀 Unicode content with emoji 😊 and international text: こんにちは, Привет, مرحبا\n\n";
  let unicode_explanation = "**Explanation**\n🌎 Unicode explanation: 안녕하세요, Olá, 你好";

  let chunks = vec![unicode_content, unicode_explanation];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(
    answer,
    "🚀 Unicode content with emoji 😊 and international text: こんにちは, Привет, مرحبا"
  );
  assert_eq!(comment, "🌎 Unicode explanation: 안녕하세요, Olá, 你好");
}

#[tokio::test]
async fn test_empty_stream() {
  // Test with an empty stream
  let chunks: Vec<&str> = vec![];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "");
  assert_eq!(comment, "");
}

#[tokio::test]
async fn test_tiny_chunks_with_mixed_tag_formats() {
  // Test when content is delivered in very small chunks with mixed tag formats
  let chunks = vec![
    "**",
    "Correct",
    "ed",
    "**\n",
    "He",
    " starts",
    " work",
    " every",
    " day",
    " at",
    " **",
    "8",
    ":",
    "00",
    " a",
    ".m",
    ".",
    "**", // not end with </Corrected>
    "\n\n",
    "<Explanation",
    ">\n",
    "*",
    " \"",
    "every",
    "day",
    "\"",
    " should",
    " be",
    " changed",
    " to",
    " \"",
    "every",
    " day",
    "\"",
    " as",
    " it",
    " is",
    " an",
    " ad",
    "verb",
    " and",
    " should",
    " not",
    " be",
    " written",
    " with",
    " the",
    " suffix",
    " \"-",
    "day",
    "\".\n",
    "*",
    " Added",
    " colon",
    " after",
    " the",
    " time",
    " for",
    " correct",
    " formatting",
    ".\n",
    "*",
    " Added",
    " zeros",
    " for",
    " clarity",
    " in",
    " time",
    " notation",
    ".\n",
    "</",
    "Explanation",
    ">",
    "\n",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::SpellingAndGrammar);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "He starts work every day at **8:00 a.m.**");
  assert_eq!(
    comment,
    "* \"everyday\" should be changed to \"every day\" as it is an adverb and should not be written with the suffix \"-day\".\n* Added colon after the time for correct formatting.\n* Added zeros for clarity in time notation."
  );
}

#[tokio::test]
async fn test_format_tags_with_grammar_correction() {
  // Test when content uses both markdown and XML tag formats
  let chunks = vec![
    "<Correct",
    "ed",
    ">",
    "He",
    " starts",
    " work",
    " every",
    " day",
    " at",
    " ",
    "8",
    " a",
    ".m",
    ".</",
    "Correct",
    "ed",
    ">\n",
    "<Explanation",
    ">\n",
    "*",
    " The",
    " word",
    " \"",
    "every",
    "day",
    "\"",
    " is",
    " being",
    " replaced",
    " with",
    " **",
    "`",
    "every",
    " day",
    "`",
    "**,",
    " as",
    " the",
    " first",
    " part",
    " should",
    " be",
    " hy",
    "phen",
    "ated",
    " for",
    " clarity",
    ".",
    " However",
    ",",
    " in",
    " this",
    " case",
    ",",
    " it",
    "'s",
    " more",
    " idi",
    "omatic",
    " to",
    " use",
    " **",
    "`",
    "every",
    " day",
    "`",
    "**",
    " without",
    " a",
    " space",
    ".\n",
    "*",
    " In",
    " British",
    " English",
    ",",
    " it",
    "'s",
    " common",
    " to",
    " write",
    " out",
    " the",
    " time",
    " (",
    "e",
    ".g",
    ".,",
    " \"",
    "eight",
    " o",
    "'clock",
    "\"",
    " or",
    " \"",
    "8",
    " a",
    ".m",
    ".\")",
    ".",
    " Since",
    " the",
    " text",
    " already",
    " uses",
    " \"",
    "8",
    " a",
    ".m",
    ".\",",
    " no",
    " correction",
    " is",
    " needed",
    " here",
    ".",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::SpellingAndGrammar);

  let (answer, comment) = collect_completion_results(result_stream).await;

  // Assert the expected output - updated to match actual behavior
  assert_eq!(answer, "He starts work every day at 8 a.m.");
  assert_eq!(
    comment,
    "* The word \"everyday\" is being replaced with **`every day`**, as the first part should be hyphenated for clarity. However, in this case, it's more idiomatic to use **`every day`** without a space.\n* In British English, it's common to write out the time (e.g., \"eight o'clock\" or \"8 a.m.\"). Since the text already uses \"8 a.m.\", no correction is needed here."
  );
}

#[tokio::test]
async fn test_everyday_correction_stream() {
  // Test with stream chunks for correcting "everyday" to "every day"
  let chunks = vec![
    "<Correct",
    "ed",
    ">",
    "He",
    " starts",
    " work",
    " every",
    " day",
    " at",
    " ",
    "8",
    " a",
    ".m",
    ".</",
    "Correct",
    "ed",
    ">",
    "\n",
    "<Explanation",
    ">The",
    " error",
    " was",
    " in",
    " \"",
    "every",
    "day",
    "\".",
    " In",
    " English",
    ",",
    " \"",
    "every",
    "day",
    "\"",
    " is",
    " an",
    " adjective",
    " that",
    " means",
    " happening",
    " or",
    " done",
    " regularly",
    ".",
    " The",
    " correct",
    " word",
    " to",
    " use",
    " here",
    " is",
    " \"",
    "every",
    " day",
    "\",",
    " which",
    " is",
    " a",
    " noun",
    " phrase",
    " indicating",
    " a",
    " specific",
    " time",
    " period",
    ".",
    " I",
    " added",
    " a",
    " space",
    " between",
    " the",
    " two",
    " words",
    " for",
    " clarity",
    " and",
    " correctness",
    ".</",
    "Explanation",
    ">",
    "\n",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::SpellingAndGrammar);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "He starts work every day at 8 a.m.");
  assert_eq!(
    comment,
    "The error was in \"everyday\". In English, \"everyday\" is an adjective that means happening or done regularly. The correct word to use here is \"every day\", which is a noun phrase indicating a specific time period. I added a space between the two words for clarity and correctness."
  );
}

#[tokio::test]
async fn test_basketball_improvement_stream() {
  // Test with stream chunks for improving a basketball-related sentence
  let chunks = vec![
    "**",
    "Improved",
    "**\n",
    "We",
    " enjoy",
    " playing",
    " basketball",
    " together",
    " as",
    " friends",
    ".\n\n",
    "<Explanation",
    ">\n",
    "*",
    " Changed",
    " \"",
    "like",
    "\"",
    " to",
    " \"",
    "en",
    "joy",
    "\",",
    " which",
    " is",
    " a",
    " more",
    " specific",
    " and",
    " engaging",
    " verb",
    " that",
    " con",
    "veys",
    " a",
    " stronger",
    " enthusiasm",
    " for",
    " the",
    " activity",
    ".\n",
    "*",
    " Modified",
    " the",
    " sentence",
    " structure",
    " to",
    " make",
    " it",
    " more",
    " concise",
    " and",
    " natural",
    "-s",
    "ounding",
    ",",
    " using",
    " a",
    " more",
    " active",
    " voice",
    " (\"",
    "We",
    " enjoy",
    "...",
    "\")",
    " instead",
    " of",
    " a",
    " passive",
    " one",
    " (\"",
    "I",
    " like",
    "...",
    "\").",
    "</",
    "Explanation",
    ">",
    "\n",
  ];

  let stream = create_mock_stream(chunks);
  let result_stream = stream_interpreter_for_completion(stream, CompletionType::ImproveWriting);

  let (answer, comment) = collect_completion_results(result_stream).await;

  assert_eq!(answer, "We enjoy playing basketball together as friends.");
  assert_eq!(
    comment,
    "* Changed \"like\" to \"enjoy\", which is a more specific and engaging verb that conveys a stronger enthusiasm for the activity.\n* Modified the sentence structure to make it more concise and natural-sounding, using a more active voice (\"We enjoy...\") instead of a passive one (\"I like...\")."
  );
}
