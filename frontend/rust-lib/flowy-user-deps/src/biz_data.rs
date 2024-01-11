use anyhow::Result;
use flowy_folder_deps::folder_builder::ParentChildViews;
use std::collections::HashMap;

pub trait UserFolderService {
  fn create_parent_child_views(&self, views: Vec<ParentChildViews>) -> Result<()>;
}

pub trait UserDatabaseService {
  fn track_database(&self, ids: HashMap<String, Vec<String>>) -> Result<()>;
}
