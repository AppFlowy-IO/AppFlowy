use collab::core::origin::CollabOrigin;
use collab::entity::EncodedCollab;
use collab::preclude::Collab;
use collab_database::database::default_database_data;
use collab_database::workspace_database::default_workspace_database_data;
use collab_document::document_data::default_document_collab_data;
use collab_entity::CollabType;
use collab_user::core::default_user_awareness_data;
use flowy_error::{FlowyError, FlowyResult};

pub async fn default_encode_collab_for_collab_type(
  _uid: i64,
  object_id: &str,
  collab_type: CollabType,
) -> FlowyResult<EncodedCollab> {
  match collab_type {
    CollabType::Document => {
      let encode_collab = default_document_collab_data(object_id)?;
      Ok(encode_collab)
    },
    CollabType::Database => default_database_data(object_id).await.map_err(Into::into),
    CollabType::WorkspaceDatabase => Ok(default_workspace_database_data(object_id)),
    CollabType::Folder => {
      // let collab = Collab::new_with_origin(CollabOrigin::Empty, object_id, vec![], false);
      // let workspace = Workspace::new(object_id.to_string(), "".to_string(), uid);
      // let folder_data = FolderData::new(workspace);
      // let folder = Folder::create(uid, collab, None, folder_data);
      // let data = folder.encode_collab_v1(|c| {
      //   collab_type
      //     .validate_require_data(c)
      //     .map_err(|err| FlowyError::invalid_data().with_context(err))?;
      //   Ok::<_, FlowyError>(())
      // })?;
      // Ok(data)
      Err(FlowyError::not_support())
    },
    CollabType::DatabaseRow => Err(FlowyError::not_support()),
    CollabType::UserAwareness => Ok(default_user_awareness_data(object_id)),
    CollabType::Unknown => {
      let collab = Collab::new_with_origin(CollabOrigin::Empty, object_id, vec![], false);
      let data = collab.encode_collab_v1(|_| Ok::<_, FlowyError>(()))?;
      Ok(data)
    },
  }
}
