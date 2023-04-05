use collab_database::database::Database as InnerDatabase;

use collab_database::fields::{Field, TypeOptionData};
use std::sync::Arc;
use tokio::sync::Mutex;

pub struct DatabaseEditor {
  database: Arc<Mutex<InnerDatabase>>,
}

impl DatabaseEditor {
  pub fn get_field(&self, _field_id: &str) -> Option<Field> {
    todo!()
  }

  pub fn update_field_type_option(
    &self,
    _view_id: &str,
    _field_id: &str,
    _type_option_data: TypeOptionData,
    _old_field: Option<Field>,
  ) {
  }
}

unsafe impl Sync for DatabaseEditor {}

unsafe impl Send for DatabaseEditor {}
