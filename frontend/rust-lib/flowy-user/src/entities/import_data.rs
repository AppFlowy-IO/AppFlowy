use flowy_derive::ProtoBuf;
use lib_infra::validator_fn::required_not_empty_str;
use validator::Validate;

#[derive(ProtoBuf, Validate, Default)]
pub struct ImportAppFlowyDataPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub path: String,

  #[pb(index = 2, one_of)]
  pub import_container_name: Option<String>,

  #[pb(index = 3, one_of)]
  pub parent_view_id: Option<String>,
}

#[derive(ProtoBuf, Validate, Default)]
pub struct UserDataPathPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub path: String,
}

#[derive(ProtoBuf, Validate, Default)]
pub struct ImportUserDataPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub path: String,

  #[pb(index = 2, one_of)]
  pub parent_view_id: Option<String>,

  #[pb(index = 3)]
  pub workspaces: Vec<WorkspaceDataPreviewPB>,
}

#[derive(ProtoBuf, Validate, Default)]
pub struct WorkspaceDataPreviewPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub created_at: i64,

  #[pb(index = 3)]
  pub workspace_id: String,

  #[pb(index = 4)]
  pub workspace_database_id: String,
}

#[derive(ProtoBuf, Validate, Default)]
pub struct UserDataPreviewPB {
  #[pb(index = 1)]
  pub user_name: String,

  #[pb(index = 2)]
  pub workspaces: Vec<WorkspaceDataPreviewPB>,
}
