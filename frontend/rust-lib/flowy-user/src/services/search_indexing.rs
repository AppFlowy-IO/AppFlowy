use flowy_error::FlowyResult;
use flowy_sqlite::search::{
  add, delete_document, delete_view, search_index, update_document, update_view, SearchData,
};

use crate::manager::UserManager;

impl UserManager {
  /// Search and returns a list of documents that match.
  pub fn search(&self, uid: i64, s: &str, limit: Option<i64>) -> FlowyResult<Vec<SearchData>> {
    let mut conn = self.db_connection(uid)?;
    let results = search_index(&mut conn, s, limit)?;
    Ok(results)
  }

  /// Adds the view to the search index with `doc_id` and `name` for the user with `uid`.
  pub fn add_view_index(&self, uid: i64, doc_id: &str, name: &str) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let view = SearchData::new_view(doc_id, name);
    add(&mut conn, &view)?;
    Ok(())
  }

  /// Updates the view to the search index with `doc_id` and `name` for the user with `uid`.
  pub fn update_view_index(&self, uid: i64, doc_id: &str, name: &str) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let view = SearchData::new_view(doc_id, name);
    update_view(&mut conn, &view)?;
    Ok(())
  }

  /// Deletes the views from the search index in `ids` for the user with `uid`.
  pub fn delete_view_index(&self, uid: i64, ids: &[String]) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    for id in ids {
      delete_view(&mut conn, id)?;
    }
    Ok(())
  }

  /// Adds the document to the search index with `view_id`, `page_id` and `text` for the user with `uid`.
  pub fn add_document_index(
    &self,
    uid: i64,
    view_id: &str,
    page_id: &str,
    text: &str,
  ) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let doc = SearchData::new_document(view_id, page_id, text);
    add(&mut conn, &doc)?;
    Ok(())
  }

  /// Updates the document to the search index with `view_id`, `page_id` and `text` for the user with `uid`.
  pub fn update_document_index(
    &self,
    uid: i64,
    view_id: &str,
    page_id: &str,
    text: &str,
  ) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let doc = SearchData::new_document(view_id, page_id, text);
    update_document(&mut conn, &doc)?;
    Ok(())
  }

  /// Deletes the views from the search index in `view_ids` for the user with `uid`.
  pub fn delete_document_index(&self, uid: i64, page_ids: &[String]) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    for id in page_ids {
      delete_document(&mut conn, id)?;
    }
    Ok(())
  }
}
