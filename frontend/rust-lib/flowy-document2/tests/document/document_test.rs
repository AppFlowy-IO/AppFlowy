use std::sync::Arc;

use flowy_document2::{document::DocumentDataWrapper, manager::DocumentManager};

use super::util::FakeUser;

#[test]
fn restore_document() {
  let user = FakeUser();
  let manager = DocumentManager::new(Arc::new(user));

  // create a document
  let doc_id: String = "1".to_string();
  let data = DocumentDataWrapper::default();
  let x = manager
    .create_document(doc_id.clone(), data.clone())
    .unwrap();

  // open a document
  let document_a = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(doc_id.clone());
  assert_eq!(document_a, data.0);

  // restore
  _ = manager.create_document(doc_id.clone(), data.clone());
  // open a document
  let document_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(doc_id.clone());

  assert_eq!(document_a, document_b);
}
