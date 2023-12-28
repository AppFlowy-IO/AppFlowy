use crate::folder_builder::ParentChildViews;
use std::collections::HashMap;

pub enum ImportData {
  AppFlowyDataFolder {
    view: ParentChildViews,
    database_view_ids_by_database_id: HashMap<String, Vec<String>>,
  },
}
