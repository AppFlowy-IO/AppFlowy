use std::convert::TryFrom;
use std::sync::Arc;

use collab_entity::{CollabObject, CollabType};
use collab_integrate::CollabKVDB;
use tracing::{error, info, instrument};

use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_pub::entities::{AppFlowyData, ImportData};
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
use flowy_user_pub::entities::{Role, UserWorkspace, WorkspaceMember};
use lib_dispatch::prelude::af_spawn;

use crate::entities::{RepeatedUserWorkspacePB, ResetWorkspacePB};
use crate::migrations::AnonUser;
use crate::notification::{send_notification, UserNotification};
use crate::services::data_import::{upload_collab_objects_data, ImportContext};
use crate::services::sqlite_sql::workspace_sql::{
  get_all_user_workspace_op, get_user_workspace_op, insert_new_workspaces_op, UserWorkspaceTable,
};
use crate::user_manager::UserManager;
use flowy_user_pub::session::Session;

impl UserManager {
  /// Import appflowy data from the given path.
  /// If the container name is not empty, then the data will be imported to the given container.
  /// Otherwise, the data will be imported to the current workspace.
  #[instrument(skip_all, err)]
  pub(crate) async fn import_appflowy_data_folder(
    &self,
    context: ImportContext,
  ) -> FlowyResult<()> {
    let session = self.get_session()?;
    let import_data = self.import_appflowy_data(context).await?;
    match import_data {
      ImportData::AppFlowyDataFolder { items } => {
        for item in items {
          self.upload_appflowy_data_item(&session, item).await?;
        }
      },
    }
    Ok(())
  }

  async fn upload_appflowy_data_item(
    &self,
    session: &Session,
    item: AppFlowyData,
  ) -> Result<(), FlowyError> {
    match item {
      AppFlowyData::Folder {
        views,
        database_view_ids_by_database_id,
      } => {
        // Since `async_trait` does not implement `Sync`, and the handler requires `Sync`, we use a
        // channel to synchronize the operation. This approach allows asynchronous trait methods to be compatible
        // with synchronous handler requirements."
        let (tx, rx) = tokio::sync::oneshot::channel();
        let cloned_workspace_service = self.user_workspace_service.clone();
        af_spawn(async move {
          let result = async {
            cloned_workspace_service
              .did_import_database_views(database_view_ids_by_database_id)
              .await?;
            cloned_workspace_service.did_import_views(views).await?;
            Ok::<(), FlowyError>(())
          }
          .await;
          let _ = tx.send(result);
        })
        .await?;
        rx.await??;
      },
      AppFlowyData::CollabObject {
        row_object_ids,
        document_object_ids,
        database_object_ids,
      } => {
        let user = self.get_user_profile_from_disk(session.user_id).await?;
        let user_collab_db = self
          .get_collab_db(session.user_id)?
          .upgrade()
          .ok_or_else(|| FlowyError::internal().with_context("Collab db not found"))?;

        let user_id = session.user_id;
        let weak_user_collab_db = Arc::downgrade(&user_collab_db);
        let weak_user_cloud_service = self.cloud_services.get_user_service()?;
        match upload_collab_objects_data(
          user_id,
          weak_user_collab_db,
          &user.workspace_id,
          &user.authenticator,
          AppFlowyData::CollabObject {
            row_object_ids,
            document_object_ids,
            database_object_ids,
          },
          weak_user_cloud_service,
        )
        .await
        {
          Ok(_) => info!(
            "Successfully uploaded collab objects data for user:{}",
            user_id
          ),
          Err(err) => {
            error!(
              "Failed to upload collab objects data: {:?} for user:{}",
              err, user_id
            );
            // TODO(nathan): retry uploading the collab objects data.
          },
        }
      },
    }
    Ok(())
  }

  pub async fn migration_anon_user_on_appflowy_cloud_sign_up(
    &self,
    old_user: &AnonUser,
    old_collab_db: &Arc<CollabKVDB>,
  ) -> FlowyResult<()> {
    let import_context = ImportContext {
      imported_session: old_user.session.clone(),
      imported_collab_db: old_collab_db.clone(),
      container_name: None,
    };
    self.import_appflowy_data_folder(import_context).await?;
    Ok(())
  }

  #[instrument(skip(self), err)]
  pub async fn open_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
    let uid = self.user_id()?;
    let _ = self
      .cloud_services
      .get_user_service()?
      .open_workspace(workspace_id)
      .await;
    if let Some(user_workspace) = self.get_user_workspace(uid, workspace_id) {
      if let Err(err) = self
        .user_status_callback
        .read()
        .await
        .open_workspace(uid, &user_workspace)
        .await
      {
        error!("Open workspace failed: {:?}", err);
      }
    }
    Ok(())
  }

  pub async fn add_workspace(&self, workspace_name: &str) -> FlowyResult<UserWorkspace> {
    let new_workspace = self
      .cloud_services
      .get_user_service()?
      .create_workspace(workspace_name)
      .await?;

    // save the workspace to sqlite db
    let uid = self.user_id()?;
    let mut conn = self.db_connection(uid)?;
    insert_new_workspaces_op(uid, &[new_workspace.clone()], &mut conn)?;
    Ok(new_workspace)
  }

  pub async fn patch_workspace(
    &self,
    workspace_id: &str,
    new_workspace_name: Option<&str>,
    new_workspace_icon: Option<&str>,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .patch_workspace(workspace_id, new_workspace_name, new_workspace_icon)
      .await?;

    Ok(())
  }

  pub async fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .delete_workspace(workspace_id)
      .await?;
    Ok(())
  }

  pub async fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .add_workspace_member(user_email, workspace_id)
      .await?;
    Ok(())
  }

  pub async fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .remove_workspace_member(user_email, workspace_id)
      .await?;
    Ok(())
  }

  pub async fn get_workspace_members(
    &self,
    workspace_id: String,
  ) -> FlowyResult<Vec<WorkspaceMember>> {
    let members = self
      .cloud_services
      .get_user_service()?
      .get_workspace_members(workspace_id)
      .await?;
    Ok(members)
  }

  pub async fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
    role: Role,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .update_workspace_member(user_email, workspace_id, role)
      .await?;
    Ok(())
  }

  pub fn get_user_workspace(&self, uid: i64, workspace_id: &str) -> Option<UserWorkspace> {
    let conn = self.db_connection(uid).ok()?;
    get_user_workspace_op(workspace_id, conn)
  }

  pub async fn get_all_user_workspaces(&self, uid: i64) -> FlowyResult<Vec<UserWorkspace>> {
    let conn = self.db_connection(uid)?;
    let workspaces = get_all_user_workspace_op(uid, conn)?;

    if let Ok(service) = self.cloud_services.get_user_service() {
      if let Ok(pool) = self.db_pool(uid) {
        af_spawn(async move {
          if let Ok(new_user_workspaces) = service.get_all_workspace(uid).await {
            if let Ok(conn) = pool.get() {
              let _ = save_user_workspaces(uid, conn, &new_user_workspaces);
              let repeated_workspace_pbs = RepeatedUserWorkspacePB::from(new_user_workspaces);
              send_notification(&uid.to_string(), UserNotification::DidUpdateUserWorkspaces)
                .payload(repeated_workspace_pbs)
                .send();
            }
          }
        });
      }
    }
    Ok(workspaces)
  }

  /// Reset the remote workspace using local workspace data. This is useful when a user wishes to
  /// open a workspace on a new device that hasn't fully synchronized with the server.
  pub async fn reset_workspace(&self, reset: ResetWorkspacePB) -> FlowyResult<()> {
    let collab_object = CollabObject::new(
      reset.uid,
      reset.workspace_id.clone(),
      CollabType::Folder,
      reset.workspace_id.clone(),
      self.authenticate_user.user_config.device_id.clone(),
    );
    self
      .cloud_services
      .get_user_service()?
      .reset_workspace(collab_object)
      .await?;
    Ok(())
  }
}

pub fn save_user_workspaces(
  uid: i64,
  mut conn: DBConnection,
  user_workspaces: &[UserWorkspace],
) -> FlowyResult<()> {
  let user_workspaces = user_workspaces
    .iter()
    .flat_map(|user_workspace| UserWorkspaceTable::try_from((uid, user_workspace)).ok())
    .collect::<Vec<UserWorkspaceTable>>();

  conn.immediate_transaction(|conn| {
    for user_workspace in user_workspaces {
      if let Err(err) = diesel::update(
        user_workspace_table::dsl::user_workspace_table
          .filter(user_workspace_table::id.eq(user_workspace.id.clone())),
      )
      .set((
        user_workspace_table::name.eq(&user_workspace.name),
        user_workspace_table::created_at.eq(&user_workspace.created_at),
        user_workspace_table::database_storage_id.eq(&user_workspace.database_storage_id),
      ))
      .execute(conn)
      .and_then(|rows| {
        if rows == 0 {
          let _ = diesel::insert_into(user_workspace_table::table)
            .values(user_workspace)
            .execute(conn)?;
        }
        Ok(())
      }) {
        tracing::error!("Error saving user workspace: {:?}", err);
      }
    }
    Ok::<(), FlowyError>(())
  })
}
