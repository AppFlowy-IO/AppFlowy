// tests/prompt_tests.rs
use flowy_ai::prompt::PromptBuilder;

#[test]
fn test_prompt_builder() {
  let prompt = PromptBuilder::new()
    .content_type("blog post".to_string())
    .topic("Plan a trip to Paris".to_string())
    .build()
    .unwrap();

  assert_eq!(prompt.content_type(), "blog post");
  assert_eq!(prompt.topic(), "Plan a trip to Paris");
}
