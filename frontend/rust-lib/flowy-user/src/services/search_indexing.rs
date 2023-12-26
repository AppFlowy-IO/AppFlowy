use flowy_error::FlowyResult;
use flowy_sqlite::search::{add_view, delete_view, update_view, View};

use crate::manager::UserManager;

impl UserManager {
  /// Adds the view to the search index with `doc_id` and `name` for the user with `uid`.
  pub fn add_view_index(&self, uid: i64, doc_id: &str, name: &str) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let view = View {
      id: doc_id.to_owned(),
      name: name.to_owned(),
    };
    add_view(&mut conn, &view)?;
    Ok(())
  }

  /// Updates the view to the search index with `doc_id` and `name` for the user with `uid`.
  pub fn update_view_index(&self, uid: i64, doc_id: &str, name: &str) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    let view = View {
      id: doc_id.to_owned(),
      name: name.to_owned(),
    };
    update_view(&mut conn, &view)?;
    Ok(())
  }

  /// Deletes the views from the search index in `ids` for the user with `uid`.
  pub fn delete_view_index(&self, uid: i64, ids: &Vec<String>) -> FlowyResult<()> {
    let mut conn = self.db_connection(uid)?;
    for id in ids {
      delete_view(&mut conn, id)?;
    }
    Ok(())
  }
}
