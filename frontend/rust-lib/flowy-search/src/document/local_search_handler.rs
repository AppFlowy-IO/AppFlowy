use async_stream::stream;
use collab_folder::ViewIcon;
use futures::Stream;
use std::fs;
use std::path::PathBuf;
use std::pin::Pin;
use std::sync::Weak;
use tantivy::directory::MmapDirectory;
use tantivy::schema::Value;
use tantivy::{Index, IndexReader, IndexWriter, TantivyDocument, Term};
use tokio::sync::RwLock;
use tracing::{error, trace, warn};
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
          yield Ok(
            CreateSearchResultPBArgs::default()
              .local_search_result(None)
              .build()
              .unwrap(),
          );
        },
        Some(state) => {
          match state.read().await.search(&workspace_id, &query) {
            Ok(items) => {
              trace!("[Tanvity] local document search result: {:?}", items);
              if items.is_empty() {
                yield Ok(
                  CreateSearchResultPBArgs::default()
                    .local_search_result(None)
                    .build()
                    .unwrap(),
                );
              } else {
                let search_result = RepeatedLocalSearchResponseItemPB { items };
                yield Ok(
                  CreateSearchResultPBArgs::default()
                    .local_search_result(Some(search_result))
                    .build()
                    .unwrap(),
                );
              }
            },
            Err(err) => error!("[Tantivy] Failed to search documents, {:?}", err),
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
  // Cached fields for better performance
  field_workspace_id: tantivy::schema::Field,
  field_object_id: tantivy::schema::Field,
  field_content: tantivy::schema::Field,
  field_name: tantivy::schema::Field,
  field_icon: tantivy::schema::Field,
  field_icon_type: tantivy::schema::Field,
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

    // Cache field lookups
    let field_workspace_id = schema
      .0
      .get_field(LocalSearchTantivySchema::WORKSPACE_ID)
      .map_err(|_| FlowyError::internal().with_context("workspace_id field missing"))?;
    let field_object_id = schema
      .0
      .get_field(LocalSearchTantivySchema::OBJECT_ID)
      .map_err(|_| FlowyError::internal().with_context("object_id field missing"))?;
    let field_content = schema
      .0
      .get_field(LocalSearchTantivySchema::CONTENT)
      .map_err(|_| FlowyError::internal().with_context("content field missing"))?;
    let field_name = schema
      .0
      .get_field(LocalSearchTantivySchema::NAME)
      .map_err(|_| FlowyError::internal().with_context("name field missing"))?;
    let field_icon = schema
      .0
      .get_field(LocalSearchTantivySchema::ICON)
      .map_err(|_| FlowyError::internal().with_context("icon field missing"))?;
    let field_icon_type = schema
      .0
      .get_field(LocalSearchTantivySchema::ICON_TYPE)
      .map_err(|_| FlowyError::internal().with_context("icon_type field missing"))?;

    Ok(Self {
      path,
      index,
      schema,
      writer,
      reader,
      workspace_id: *workspace_id,
      field_workspace_id,
      field_object_id,
      field_content,
      field_name,
      field_icon,
      field_icon_type,
    })
  }

  pub fn add_document(
    &mut self,
    id: &str,
    content: String,
    name: Option<String>,
    icon: Option<ViewIcon>,
  ) -> FlowyResult<()> {
    trace!("[Tantivy] Adding document with id:{}, name:{:?}", id, name);
    let term = Term::from_field_text(self.field_object_id, id);
    let searcher = self.reader.searcher();
    let query =
      tantivy::query::TermQuery::new(term.clone(), tantivy::schema::IndexRecordOption::Basic);
    let top_docs = searcher.search(&query, &tantivy::collector::TopDocs::with_limit(1))?;

    let (existing_name, existing_icon) = if let Some((_score, doc_address)) = top_docs.first() {
      let retrieved: TantivyDocument = searcher.doc(*doc_address)?;

      // Get existing name if needed
      let existing_name = if name.is_none() {
        retrieved
          .get_first(self.field_name)
          .and_then(|v| v.as_str())
          .map(|s| s.to_string())
      } else {
        None
      };

      // Get existing icon if needed
      let existing_icon = if icon.is_none() {
        let icon_value = retrieved
          .get_first(self.field_icon)
          .and_then(|v| v.as_str())
          .map(|s| s.to_string());

        if let Some(icon_value) = icon_value {
          let icon_type_str = retrieved
            .get_first(self.field_icon_type)
            .and_then(|v| v.as_str())
            .unwrap_or_default();

          let icon_type = icon_type_str.parse::<u8>().unwrap_or_default();

          // Recreate the ViewIcon from stored values
          Some(ViewIcon {
            value: icon_value,
            ty: icon_type.into(),
          })
        } else {
          None
        }
      } else {
        None
      };

      (existing_name, existing_icon)
    } else {
      (None, None)
    };

    // Delete existing document with same ID
    self.writer.delete_term(term);

    // Use existing values if new ones not provided
    let final_name = name.or(existing_name);
    let final_icon = icon.or(existing_icon);

    // Ensure we have a name
    let document_name = final_name.unwrap_or_else(|| String::from("Untitled"));

    // Create base document with required fields
    let mut doc_builder = tantivy::doc!(
        self.field_workspace_id => self.workspace_id.to_string(),
        self.field_object_id => id,
        self.field_content => content,
        self.field_name => document_name
    );

    // Only add icon fields if icon is present
    if let Some(view_icon) = final_icon {
      doc_builder.add_text(self.field_icon, view_icon.value);
      doc_builder.add_text(self.field_icon_type, (view_icon.ty as u8).to_string());
    }

    self.writer.add_document(doc_builder)?;
    self.writer.commit()?;

    Ok(())
  }

  pub fn add_document_metadata(
    &mut self,
    id: &str,
    name: Option<String>,
    icon: Option<ViewIcon>,
  ) -> FlowyResult<()> {
    let term = Term::from_field_text(self.field_object_id, id);
    let searcher = self.reader.searcher();
    let query =
      tantivy::query::TermQuery::new(term.clone(), tantivy::schema::IndexRecordOption::Basic);

    // Search for the document
    let top_docs = searcher.search(&query, &tantivy::collector::TopDocs::with_limit(1))?;

    let (existing_content, existing_name, existing_icon) =
      if let Some((_score, doc_address)) = top_docs.first() {
        let retrieved: TantivyDocument = searcher.doc(*doc_address)?;

        // Get existing content
        let content = retrieved
          .get_first(self.field_content)
          .and_then(|v| v.as_str())
          .unwrap_or_default()
          .to_string();

        // Get existing name if needed
        let existing_name = if name.is_none() {
          retrieved
            .get_first(self.field_name)
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
        } else {
          None
        };

        // Get existing icon if needed
        let existing_icon = if icon.is_none() {
          let icon_value = retrieved
            .get_first(self.field_icon)
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());

          if let Some(icon_value) = icon_value {
            let icon_type_str = retrieved
              .get_first(self.field_icon_type)
              .and_then(|v| v.as_str())
              .unwrap_or_default();

            let icon_type = icon_type_str.parse::<u8>().unwrap_or_default();

            Some(ViewIcon {
              value: icon_value,
              ty: icon_type.into(),
            })
          } else {
            None
          }
        } else {
          None
        };

        (content, existing_name, existing_icon)
      } else {
        (String::new(), None, None)
      };

    // Use existing values if new ones not provided
    let final_name = name.or(existing_name);
    let final_icon = icon.or(existing_icon);

    // Ensure we have a name
    let document_name = final_name.unwrap_or_else(|| String::from("Untitled"));

    // Delete existing document
    self.writer.delete_term(term);

    // Create base document with required fields
    let mut doc_builder = tantivy::doc!(
        self.field_workspace_id => self.workspace_id.to_string(),
        self.field_object_id => id,
        self.field_content => existing_content,
        self.field_name => document_name
    );

    // Only add icon fields if icon is present
    if let Some(view_icon) = final_icon {
      doc_builder.add_text(self.field_icon, view_icon.value);
      doc_builder.add_text(self.field_icon_type, (view_icon.ty as u8).to_string());
    }

    self.writer.add_document(doc_builder)?;
    self.writer.commit()?;

    Ok(())
  }

  pub fn delete_workspace(&mut self, workspace_id: &Uuid) -> FlowyResult<()> {
    let term = Term::from_field_text(self.field_workspace_id, &workspace_id.to_string());
    self.writer.delete_term(term);
    self.writer.commit()?;

    Ok(())
  }

  /// Delete a document (all fields) matching this `object_id`
  pub fn delete_document(&mut self, id: &str) -> FlowyResult<()> {
    trace!("[Tantivy] delete document with id: {}", id);
    let term = Term::from_field_text(self.field_object_id, id);
    self.writer.delete_term(term);
    self.writer.commit()?;

    Ok(())
  }

  pub fn delete_documents(&mut self, ids: &[String]) -> FlowyResult<()> {
    trace!("[Tantivy] delete documents with ids: {:?}", ids);
    for id in ids {
      let term = Term::from_field_text(self.field_object_id, id);
      self.writer.delete_term(term);
    }
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

    // Use cached fields for query parser
    let mut qp = tantivy::query::QueryParser::for_index(
      &self.index,
      vec![self.field_content, self.field_name],
    );
    // Enable fuzzy matching for name field (better user experience for typos)
    qp.set_field_fuzzy(self.field_name, true, 2, true);

    let query = qp.parse_query(query)?;
    let top_docs = searcher.search(&query, &tantivy::collector::TopDocs::with_limit(10))?;

    let mut results = Vec::with_capacity(top_docs.len());
    let mut seen_ids = std::collections::HashSet::new();

    for (_score, doc_address) in top_docs {
      let retrieved: TantivyDocument = searcher.doc(doc_address)?;
      // Pull out each stored field using cached field references
      let workspace_id_str = retrieved
        .get_first(self.field_workspace_id)
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();

      if workspace_id != workspace_id_str {
        warn!(
          "[Tantivy] Document workspace_id mismatch: {} != {}",
          workspace_id, workspace_id_str
        );
        continue;
      }

      let object_id = retrieved
        .get_first(self.field_object_id)
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
        .get_first(self.field_name)
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();

      // Get icon value and type
      let icon = {
        let icon_value = retrieved
          .get_first(self.field_icon)
          .and_then(|v| v.as_str())
          .unwrap_or_default()
          .to_string();

        // Only proceed with creating an icon if we have an actual value
        if !icon_value.is_empty() {
          let icon_type_str = retrieved
            .get_first(self.field_icon_type)
            .and_then(|v| v.as_str())
            .unwrap_or_default();

          let icon_type: ResultIconTypePB = match icon_type_str.parse::<i64>() {
            Ok(val) => val.into(),
            Err(_) => ResultIconTypePB::default(),
          };

          Some(ResultIconPB {
            ty: icon_type,
            value: icon_value,
          })
        } else {
          None
        }
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
