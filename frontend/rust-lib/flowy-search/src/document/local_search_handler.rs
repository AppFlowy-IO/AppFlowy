use async_stream::stream;
use collab_folder::ViewIcon;
use futures::Stream;
use std::fs;
use std::path::PathBuf;
use std::pin::Pin;
use std::sync::Weak;
use tantivy::directory::MmapDirectory;
use tantivy::schema::Value;
use tantivy::{doc, Index, IndexReader, IndexWriter, TantivyDocument, Term};
use tokio::sync::RwLock;
use tracing::{error, info, trace, warn};
use uuid::Uuid;

use crate::entities::{
  CreateSearchResultPBArgs, LocalSearchResponseItemPB, RepeatedLocalSearchResponseItemPB,
  ResultIconPB, ResultIconTypePB, SearchResponsePB,
};
use crate::schema::LocalSearchTantivySchema;
use crate::services::manager::{SearchHandler, SearchType};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;

pub struct DocumentLocalSearchHandler {
  state: Weak<RwLock<DocumentTantivyState>>,
}

impl DocumentLocalSearchHandler {
  pub fn new(state: Weak<RwLock<DocumentTantivyState>>) -> Self {
    Self { state }
  }
}

#[async_trait]
impl SearchHandler for DocumentLocalSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::DocumentLocal
  }

  async fn perform_search(
    &self,
    query: String,
    workspace_id: &Uuid,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>> {
    let workspace_id = *workspace_id;
    let state = self.state.clone();
    Box::pin(stream! {
      match state.upgrade() {
        None => {
          // Do nothing if the state is not available
        },
        Some(state) => {
          if let Ok(items) = state.read().await.search(&workspace_id, &query) {
            trace!("[Tanvity] local document search result: {:?}", items);
           let search_result = RepeatedLocalSearchResponseItemPB { items };
           yield Ok(
             CreateSearchResultPBArgs::default()
               .searching(false)
               .local_search_result(Some(search_result))
               .build()
               .unwrap(),
           );
          }
        }
      }
    })
  }
}

/// Holds the Tantivy index state for a workspace's documents.
pub struct DocumentTantivyState {
  pub path: PathBuf,
  pub index: Index,
  pub schema: LocalSearchTantivySchema,
  pub writer: IndexWriter,
  pub reader: IndexReader,
  pub workspace_id: Uuid,
}

impl DocumentTantivyState {
  pub fn new(workspace_id: &Uuid, path: PathBuf) -> FlowyResult<Self> {
    let index_path = path.join(workspace_id.to_string()).join("documents");
    if !index_path.exists() {
      fs::create_dir_all(&index_path).map_err(|e| {
        error!("Failed to create index directory: {:?}", e);
        FlowyError::internal().with_context("Failed to create folder index")
      })?;
    }

    let schema = LocalSearchTantivySchema::new();
    let dir = MmapDirectory::open(&index_path)?;
    let index = Index::open_or_create(dir, schema.0.clone())?;
    let writer = index.writer(15_000_000)?; // 15 MB buffer
    let reader = index.reader()?;

    Ok(Self {
      path,
      index,
      schema,
      writer,
      reader,
      workspace_id: *workspace_id,
    })
  }

  pub fn add_document(
    &mut self,
    id: &str,
    content: String,
    name: String,
    icon: Option<ViewIcon>,
  ) -> FlowyResult<()> {
    info!("[Tanvity] Adding document with id:{}, name:{}", id, name);

    // look up your fields by name once
    let f_workspace = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::WORKSPACE_ID)
      .expect("workspace_id field missing");
    let f_object = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::OBJECT_ID)
      .expect("object_id field missing");
    let f_content = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::CONTENT)
      .expect("content field missing");

    let f_name = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::NAME)
      .expect("name field missing");

    let f_icon = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::ICON)
      .expect("icon field missing");

    let f_icon_type = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::ICON_TYPE)
      .expect("icon field missing");

    let (icon, icon_type) = icon.map(|v| (v.value, v.ty as u8)).unwrap_or_default();

    let tantivy_doc = doc!(
        f_workspace => self.workspace_id.to_string(),
        f_object    => id,
        f_content   => content,
        f_name => name,
        f_icon => icon,
        f_icon_type=> icon_type.to_string()
    );

    self.writer.add_document(tantivy_doc)?;
    self.writer.commit()?;

    Ok(())
  }

  /// Delete a document (all fields) matching this `object_id`
  pub fn delete_document(&mut self, id: &str) -> FlowyResult<()> {
    info!("[Tanvity] Deleting document with id: {}", id);
    let object_field = self
      .schema
      .0
      .get_field(LocalSearchTantivySchema::OBJECT_ID)
      .expect("object_id field missing");
    let term = Term::from_field_text(object_field, id);

    self.writer.delete_term(term);
    self.writer.commit()?;

    Ok(())
  }

  pub fn search(
    &self,
    workspace_id: &Uuid,
    query: &str,
  ) -> FlowyResult<Vec<LocalSearchResponseItemPB>> {
    let workspace_id = workspace_id.to_string();
    let reader = self.reader.clone();
    let searcher = reader.searcher();
    let schema = self.schema.0.clone();
    let qp = tantivy::query::QueryParser::for_index(
      &self.index,
      vec![
        schema.get_field(LocalSearchTantivySchema::CONTENT)?,
        schema.get_field(LocalSearchTantivySchema::NAME)?,
      ],
    );
    let query = qp.parse_query(query)?;
    let top_docs = searcher.search(&query, &tantivy::collector::TopDocs::with_limit(10))?;

    // pre-look up the fields once
    let f_workspace = schema
      .get_field(LocalSearchTantivySchema::WORKSPACE_ID)
      .unwrap();
    let f_object = schema
      .get_field(LocalSearchTantivySchema::OBJECT_ID)
      .unwrap();
    let f_name = schema.get_field(LocalSearchTantivySchema::NAME).unwrap();
    let f_icon = schema.get_field(LocalSearchTantivySchema::ICON).ok();
    let f_icon_type = schema.get_field(LocalSearchTantivySchema::ICON_TYPE).ok();

    let mut results = Vec::with_capacity(top_docs.len());
    let mut seen_ids = std::collections::HashSet::new();
    for (_score, doc_address) in top_docs {
      let retrieved: TantivyDocument = searcher.doc(doc_address)?;

      // pull out each stored field
      let workspace_id_str = retrieved
        .get_first(f_workspace)
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();
      if workspace_id != workspace_id_str {
        warn!(
          "[Tanvity] Document workspace_id mismatch: {} != {}",
          workspace_id, workspace_id_str
        );
        continue;
      }

      let object_id = retrieved
        .get_first(f_object)
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();

      // Skip records with empty object_id and workspace_id
      if object_id.is_empty() && workspace_id_str.is_empty() {
        continue;
      }

      // Skip duplicate records based on object_id
      if !seen_ids.insert(object_id.clone()) {
        continue;
      }

      let name = retrieved
        .get_first(f_name)
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();

      // Get icon value and type if available
      let icon = match (f_icon, f_icon_type) {
        (Some(icon_field), Some(icon_type_field)) => {
          let icon_value = retrieved
            .get_first(icon_field)
            .and_then(|v| v.as_str())
            .unwrap_or_default()
            .to_string();

          let icon_type_str = retrieved
            .get_first(icon_type_field)
            .and_then(|v| v.as_str())
            .unwrap_or_default();

          let icon_type: ResultIconTypePB = match icon_type_str.parse::<i64>() {
            Ok(val) => val.into(),
            Err(_) => ResultIconTypePB::default(),
          };

          if icon_value.is_empty() {
            None
          } else {
            Some(ResultIconPB {
              ty: icon_type,
              value: icon_value,
            })
          }
        },
        _ => None,
      };

      results.push(LocalSearchResponseItemPB {
        id: object_id,
        display_name: name,
        icon,
        workspace_id: workspace_id_str,
      });
    }

    Ok(results)
  }
}
