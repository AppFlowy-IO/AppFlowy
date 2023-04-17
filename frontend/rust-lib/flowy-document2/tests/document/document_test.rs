use std::sync::Arc;

use flowy_document2::{document::DocumentDataWrapper, manager::DocumentManager};
use nanoid::nanoid;

use super::util::FakeUser;

#[test]
fn restore_document() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user));

  // create a document
  let doc_id: String = nanoid!(10);
  let data = DocumentDataWrapper::default();
  let document_a = manager
    .create_document(doc_id.clone(), data.clone())
    .unwrap();
  let data_a = document_a.lock().get_document().unwrap();
  assert_eq!(data_a, data.0);

  // open a document
  let data_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(doc_id.clone());
  assert_eq!(data_b, data.0);

  // restore
  _ = manager.create_document(doc_id.clone(), data.clone());
  // open a document
  let data_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(doc_id.clone());

  assert_eq!(data_b, data.0);
}
