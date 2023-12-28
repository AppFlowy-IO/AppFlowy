use flowy_error::FlowyError;
use flowy_folder_deps::folder_builder::ParentChildViews;

pub trait UserFolderAction {
  fn create_view(view: ParentChildViews) -> Result<(), FlowyError>;
}
