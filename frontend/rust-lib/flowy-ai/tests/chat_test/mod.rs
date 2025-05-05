use crate::setup_log;
use flowy_ai::embeddings::store::{SqliteVectorStore, SOURCE_ID};
use flowy_ai::local_ai::chat::llm::LLMOllama;
use flowy_ai::local_ai::chat::llm_chat::LLMChat;
use flowy_ai::local_ai::chat::related_question_chain::RelatedQuestionChain;
use flowy_ai_pub::cloud::{OutputLayout, QuestionStreamValue, ResponseFormat, StreamAnswer};
use flowy_sqlite_vec::db::VectorSqliteDB;
use ollama_rs::Ollama;
use reqwest::Url;
use std::sync::Arc;
use tempfile::tempdir;
use tokio::sync::RwLock;
use tokio_stream::StreamExt;
use uuid::Uuid;

pub struct TestContext {
  ollama: Arc<Ollama>,
  store: SqliteVectorStore,
  #[allow(dead_code)]
  db: Arc<VectorSqliteDB>,
  #[allow(dead_code)]
  vector_store: SqliteVectorStore,
}

impl TestContext {
  pub fn new() -> anyhow::Result<Self> {
    let ollama_url = "http://localhost:11434";

    let url = Url::parse(ollama_url)?;
    let ollama = Arc::new(Ollama::from_url(url.clone()));

    let temp_dir = tempdir()?;
    let db = Arc::new(VectorSqliteDB::new(temp_dir.into_path())?);

    let vector_store = SqliteVectorStore::new(Arc::downgrade(&ollama), Arc::downgrade(&db));

    Ok(Self {
      ollama,
      store: vector_store.clone(),
      db,
      vector_store,
    })
  }

  pub async fn create_chat(&self, rag_ids: Vec<String>) -> LLMChat {
    let workspace_id = Uuid::new_v4();
    let chat_id = Uuid::new_v4();
    let model = "llama3.1";
    let ollama_client = Arc::new(RwLock::new(Some(Arc::downgrade(&self.ollama))));

    LLMChat::new(
      workspace_id,
      chat_id,
      model,
      ollama_client,
      Some(self.store.clone()),
      rag_ids,
    )
    .await
    .unwrap()
  }
}

#[tokio::test]
async fn local_ollama_test_simple_question() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let stream = chat
    .stream_question("hello world", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(result);
}

#[tokio::test]
async fn local_ollama_test_chat_context_retrieve() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let mut ids = vec![];

  for (doc, id) in  [("Rust is a multiplayer survival game developed by Facepunch Studios, first released in early access in December 2013 and fully launched in February 2018. It has since become one of the most popular games in the survival genre, known for its harsh environment, intricate crafting system, and player-driven dynamics. The game is available on Windows, macOS, and PlayStation, with a community-driven approach to updates and content additions.", uuid::Uuid::new_v4()),
        ("Rust is a modern, system-level programming language designed with a focus on performance, safety, and concurrency. It was created by Mozilla and first released in 2010, with its 1.0 version launched in 2015. Rust is known for providing the control and performance of languages like C and C++, but with built-in safety features that prevent common programming errors, such as memory leaks, data races, and buffer overflows.", uuid::Uuid::new_v4()),
        ("Rust as a Natural Process (Oxidation) refers to the chemical reaction that occurs when metals, primarily iron, come into contact with oxygen and moisture (water) over time, leading to the formation of iron oxide, commonly known as rust. This process is a form of oxidation, where a substance reacts with oxygen in the air or water, resulting in the degradation of the metal.", uuid::Uuid::new_v4())] {
        ids.push(id.to_string());
        chat.embed_paragraphs(&id.to_string(), vec![doc.to_string()]).await.unwrap();
    }
  chat.set_rag_ids(ids.clone()).await.unwrap();

  let stream = chat
    .stream_question("Rust is a multiplayer survival game", Default::default())
    .await
    .unwrap();
  let (answer, sources) = collect_stream(stream).await;
  dbg!(&answer);
  dbg!(&sources);

  assert!(!answer.is_empty());
  assert_eq!(sources.len(), 1);
}

#[tokio::test]
async fn local_ollama_test_chat_format() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let mut format = ResponseFormat::new();
  format.output_layout = OutputLayout::SimpleTable;

  let stream = chat
    .stream_question("Compare rust and js", format)
    .await
    .unwrap();
  let (answer, _) = collect_stream(stream).await;
  dbg!(&answer);
  assert!(!answer.is_empty());
}

async fn collect_stream(stream: StreamAnswer) -> (String, Vec<String>) {
  let mut result = String::new();
  let mut sources = vec![];
  let mut stream = stream;
  while let Some(chunk) = stream.next().await {
    match chunk {
      Ok(value) => match value {
        QuestionStreamValue::Answer { value } => {
          result.push_str(&value);
        },
        QuestionStreamValue::Metadata { value } => {
          sources.push(value.get(SOURCE_ID).unwrap().to_string());
        },
        QuestionStreamValue::KeepAlive => {},
      },
      Err(e) => {
        eprintln!("Error: {}", e);
      },
    }
  }

  (result, sources)
}

#[tokio::test]
async fn local_ollama_test_chat_related_question() {
  setup_log();

  let ollama = LLMOllama::default().with_model("llama3.1");
  let chain = RelatedQuestionChain::new(ollama);
  let resp = chain
    .related_question("Compare rust with JS")
    .await
    .unwrap();

  dbg!(&resp);
  assert_eq!(resp.len(), 3);
}
