use collab_database::database::Database as InnerDatabase;

use collab_database::fields::{Field, TypeOptionData};
use std::sync::Arc;
use tokio::sync::Mutex;

pub struct DatabaseEditor {
  database: Arc<Mutex<InnerDatabase>>,
}

impl DatabaseEditor {
  pub fn get_field(&self, field_id: &str) -> Option<Field> {
    todo!()
  }

  pub fn update_field_type_option(
    &self,
    view_id: &str,
    field_id: &str,
    type_option_data: TypeOptionData,
    old_field: Option<Field>,
  ) {
  }
}

unsafe impl Sync for DatabaseEditor {}

unsafe impl Send for DatabaseEditor {}
