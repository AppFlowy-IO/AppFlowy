use collab_database::database::Database as InnerDatabase;

use std::sync::Arc;
use tokio::sync::Mutex;

pub struct DatabaseEditor {
  database: Arc<Mutex<InnerDatabase>>,
}

unsafe impl Sync for DatabaseEditor {}

unsafe impl Send for DatabaseEditor {}
