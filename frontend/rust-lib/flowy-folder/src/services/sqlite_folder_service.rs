// use flowy_error::FlowyError;
// use flowy_sqlite::DBConnection;
// use std::sync::Arc;

// use crate::services::sqlite_sql::{folder_sql, migration};

// pub struct SQLiteFolderService {
//   database: Arc<dyn SQLiteFolderDatabase>,
// }

// impl SQLiteFolderService {
//   pub fn new(database: Arc<dyn SQLiteFolderDatabase>) -> Self {
//     Self { database }
//   }

//   pub async fn initialize(&self) -> Result<(), FlowyError> {
//     // Run database migrations
//     let conn = self.database.get_connection()?;
//     migration::run_migrations("folder", conn).await?;
//     Ok(())
//   }

//   pub async fn create_folder_view(
//     &self,
//     folder_view: folder_sql::FolderView,
//   ) -> Result<(), FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::create_folder_view(folder_view, conn)
//   }

//   pub async fn update_folder_view(
//     &self,
//     changeset: folder_sql::FolderTableChangeset,
//   ) -> Result<(), FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::update_folder_view(changeset, conn)
//   }

//   pub async fn delete_folder_view(&self, view_id: &str) -> Result<(), FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::delete_folder_view(view_id, conn)
//   }

//   pub async fn delete_workspace_folders(&self, workspace_id: &str) -> Result<(), FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::delete_workspace_folders(workspace_id, conn)
//   }

//   pub async fn get_folder_views_by_workspace_id(
//     &self,
//     workspace_id: &str,
//   ) -> Result<Vec<folder_sql::FolderView>, FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::select_workspace_folders(workspace_id, conn)
//   }

//   pub async fn get_folder_view_by_id(
//     &self,
//     view_id: &str,
//   ) -> Result<folder_sql::FolderView, FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::select_folder_view(view_id, conn)
//   }

//   pub async fn get_folder_views_by_parent(
//     &self,
//     workspace_id: &str,
//     parent_id: &str,
//   ) -> Result<Vec<folder_sql::FolderView>, FlowyError> {
//     let conn = self.database.get_connection()?;
//     folder_sql::select_folder_views_by_parent(workspace_id, parent_id, conn)
//   }
// }

// pub trait SQLiteFolderDatabase: Send + Sync {
//   fn get_connection(&self) -> Result<DBConnection, FlowyError>;
// }
