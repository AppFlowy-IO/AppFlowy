use crate::entities::{CreateViewParams, ViewDataFormatPB, WorkspacePB};
use crate::view_ext::{ViewDataProcessor, ViewDataProcessorMap};
use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::preclude::CollabBuilder;
use collab_folder::core::{Folder, View, ViewLayout};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use std::collections::HashMap;
use std::fmt::Formatter;
use std::sync::Arc;

pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
}

pub struct FolderManager {
  folder: Arc<Folder>,
  view_processors: ViewDataProcessorMap,
}

impl FolderManager {
  pub fn new(
    user: Arc<dyn FolderUser>,
    db: Arc<CollabKV>,
    view_processors: ViewDataProcessorMap,
  ) -> FlowyResult<Self> {
    let disk_plugin = CollabDiskPlugin::new(db).unwrap();
    let folder_id = FolderId::new(user.user_id()?);
    let collab = CollabBuilder::new(1, folder_id)
      .with_plugin(disk_plugin)
      .build();
    let folder = Folder::create(collab);
    Ok(Self {
      folder: Arc::new(folder),
      view_processors,
    })
  }

  /// Called immediately after the application launched with the user sign in/sign up.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn initialize(&self, user_id: &str, token: &str) -> FlowyResult<()> {
    todo!()
  }

  pub async fn get_current_workspace(&self) -> FlowyResult<WorkspacePB> {
    todo!()
  }

  pub async fn initialize_with_new_user(
    &self,
    user_id: &str,
    token: &str,
    view_data_format: ViewDataFormatPB,
  ) -> FlowyResult<()> {
    todo!()
  }

  /// Called when the current user logout
  ///
  pub async fn clear(&self, user_id: &str) {
    todo!()
  }

  pub async fn create_view_with_params(&self, params: CreateViewParams) -> FlowyResult<View> {
    let view_layout: ViewLayout = params.layout.clone().into();
    let processor = self.get_data_processor(params.data_format.clone())?;
  }

  pub async fn create_view_data(
    &self,
    view_id: &str,
    name: &str,
    view_layout: ViewLayout,
    data: Vec<u8>,
  ) -> FlowyResult<()> {
    let user_id = self.user.user_id()?;
    let processor = self.get_data_processor(&view_layout)?;
    processor
      .create_view_with_custom_data(
        &user_id,
        view_id,
        name,
        data,
        view_layout,
        HashMap::default(),
      )
      .await?;
    Ok(())
  }

  fn get_data_processor(
    &self,
    layout_type: &ViewLayout,
  ) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
    match self.view_processors.get(&layout_type) {
      None => Err(FlowyError::internal().context(format!(
        "Get data processor failed. Unknown layout type: {:?}",
        layout_type
      ))),
      Some(processor) => Ok(processor.clone()),
    }
  }
}

#[derive(Clone)]
pub struct FolderId(String);
impl FolderId {
  pub fn new(uid: i64) -> Self {
    Self(format!("{}:folder", uid))
  }
}
