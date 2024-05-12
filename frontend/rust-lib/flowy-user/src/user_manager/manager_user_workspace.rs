use std::convert::TryFrom;
use std::sync::Arc;

use collab_entity::{CollabObject, CollabType};
use collab_integrate::CollabKVDB;
use tracing::{error, info, instrument, warn};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_pub::entities::{AppFlowyData, ImportData};
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
use flowy_user_pub::entities::{
  Role, UserWorkspace, WorkspaceInvitation, WorkspaceInvitationStatus, WorkspaceMember,
  WorkspaceSubscription,
};
use lib_dispatch::prelude::af_spawn;

use crate::entities::{
  RepeatedUserWorkspacePB, ResetWorkspacePB, SubscribeWorkspacePB, UserWorkspacePB,
};
use crate::migrations::AnonUser;
use crate::notification::{send_notification, UserNotification};
use crate::services::data_import::{
  generate_import_data, upload_collab_objects_data, ImportedFolder, ImportedSource,
};
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
  pub(crate) async fn perform_import(&self, imported_folder: ImportedFolder) -> FlowyResult<()> {
    let current_session = self.get_session()?;
    let user_collab_db = self
      .authenticate_user
      .database
      .get_collab_db(current_session.user_id)?;

    let cloned_current_session = current_session.clone();
    let import_data = tokio::task::spawn_blocking(move || {
      generate_import_data(
        &cloned_current_session,
        &cloned_current_session.user_workspace.id,
        &user_collab_db,
        imported_folder,
      )
      .map_err(|err| FlowyError::new(ErrorCode::AppFlowyDataFolderImportError, err.to_string()))
    })
    .await??;

    match import_data {
      ImportData::AppFlowyDataFolder { items } => {
        for item in items {
          self
            .upload_appflowy_data_item(&current_session, item)
            .await?;
        }
      },
    }
    Ok(())
  }

  async fn upload_appflowy_data_item(
    &self,
    current_session: &Session,
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
        let user = self
          .get_user_profile_from_disk(current_session.user_id)
          .await?;
        let user_collab_db = self
          .get_collab_db(current_session.user_id)?
          .upgrade()
          .ok_or_else(|| FlowyError::internal().with_context("Collab db not found"))?;

        let user_id = current_session.user_id;
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
    let import_context = ImportedFolder {
      imported_session: old_user.session.clone(),
      imported_collab_db: old_collab_db.clone(),
      container_name: None,
      source: ImportedSource::AnonUser,
    };
    self.perform_import(import_context).await?;
    Ok(())
  }

  #[instrument(skip(self), err)]
  pub async fn open_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
    info!("open workspace: {}", workspace_id);
    let user_workspace = self
      .cloud_services
      .get_user_service()?
      .open_workspace(workspace_id)
      .await?;

    self
      .authenticate_user
      .set_user_workspace(user_workspace.clone())?;

    if let Err(err) = self.try_initial_user_awareness(&self.get_session()?).await {
      error!(
        "Failed to initialize user awareness when opening workspace: {:?}",
        err
      );
    }

    let uid = self.user_id()?;
    if let Err(err) = self
      .user_status_callback
      .read()
      .await
      .open_workspace(uid, &user_workspace)
      .await
    {
      error!("Open workspace failed: {:?}", err);
    }

    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn add_workspace(&self, workspace_name: &str) -> FlowyResult<UserWorkspace> {
    let new_workspace = self
      .cloud_services
      .get_user_service()?
      .create_workspace(workspace_name)
      .await?;

    info!(
      "new workspace: {}, name:{}",
      new_workspace.id, new_workspace.name
    );

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

    // save the icon and name to sqlite db
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    let mut user_workspace = match self.get_user_workspace(uid, workspace_id) {
      Some(user_workspace) => user_workspace,
      None => {
        return Err(FlowyError::record_not_found().with_context(format!(
          "Expected to find user workspace with id: {}, but not found",
          workspace_id
        )));
      },
    };

    if let Some(new_workspace_name) = new_workspace_name {
      user_workspace.name = new_workspace_name.to_string();
    }
    if let Some(new_workspace_icon) = new_workspace_icon {
      user_workspace.icon = new_workspace_icon.to_string();
    }

    let _ = save_user_workspace(uid, conn, &user_workspace);

    let payload: UserWorkspacePB = user_workspace.clone().into();
    send_notification(&uid.to_string(), UserNotification::DidUpdateUserWorkspace)
      .payload(payload)
      .send();

    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn leave_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
    info!("leave workspace: {}", workspace_id);
    self
      .cloud_services
      .get_user_service()?
      .leave_workspace(workspace_id)
      .await?;

    // delete workspace from local sqlite db
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    delete_user_workspaces(conn, workspace_id)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()> {
    info!("delete workspace: {}", workspace_id);
    self
      .cloud_services
      .get_user_service()?
      .delete_workspace(workspace_id)
      .await?;
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    delete_user_workspaces(conn, workspace_id)?;
    Ok(())
  }

  pub async fn invite_member_to_workspace(
    &self,
    workspace_id: String,
    invitee_email: String,
    role: Role,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .invite_workspace_member(invitee_email, workspace_id, role)
      .await?;
    Ok(())
  }

  pub async fn list_pending_workspace_invitations(&self) -> FlowyResult<Vec<WorkspaceInvitation>> {
    let status = Some(WorkspaceInvitationStatus::Pending);
    let invitations = self
      .cloud_services
      .get_user_service()?
      .list_workspace_invitations(status)
      .await?;
    Ok(invitations)
  }

  pub async fn accept_workspace_invitation(&self, invite_id: String) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .accept_workspace_invitations(invite_id)
      .await?;
    Ok(())
  }

  // deprecated, use invite instead
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
              let _ = save_all_user_workspaces(uid, conn, &new_user_workspaces);
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

  #[instrument(level = "info", skip(self), err)]
  pub async fn subscribe_workspace(
    &self,
    workspace_subscription: SubscribeWorkspacePB,
  ) -> FlowyResult<String> {
    let payment_link = self
      .cloud_services
      .get_user_service()?
      .subscribe_workspace(
        workspace_subscription.workspace_id,
        workspace_subscription.recurring_interval.into(),
        workspace_subscription.workspace_subscription_plan.into(),
        workspace_subscription.success_url,
      )
      .await?;

    Ok(payment_link)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn get_workspace_subscriptions(&self) -> FlowyResult<Vec<WorkspaceSubscription>> {
    let res = self
      .cloud_services
      .get_user_service()?
      .get_workspace_subscriptions()
      .await?;
    Ok(res)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn cancel_workspace_subscription(&self, workspace_id: String) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .cancel_workspace_subscription(workspace_id)
      .await?;
    Ok(())
  }
}

/// This method is used to save one user workspace to the SQLite database
///
/// If the workspace is already persisted in the database, it will be overridden.
///
/// Consider using [save_all_user_workspaces] if you need to override all workspaces of the user.
///
pub fn save_user_workspace(
  uid: i64,
  mut conn: DBConnection,
  user_workspace: &UserWorkspace,
) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    let user_workspace = UserWorkspaceTable::try_from((uid, user_workspace))?;
    let affected_rows = diesel::update(
      user_workspace_table::dsl::user_workspace_table
        .filter(user_workspace_table::id.eq(&user_workspace.id)),
    )
    .set((
      user_workspace_table::name.eq(&user_workspace.name),
      user_workspace_table::created_at.eq(&user_workspace.created_at),
      user_workspace_table::database_storage_id.eq(&user_workspace.database_storage_id),
      user_workspace_table::icon.eq(&user_workspace.icon),
    ))
    .execute(conn)?;

    if affected_rows == 0 {
      diesel::insert_into(user_workspace_table::table)
        .values(user_workspace)
        .execute(conn)?;
    }

    Ok::<(), FlowyError>(())
  })
}

/// This method is used to save the user workspaces (plural) to the SQLite database
///
/// The workspaces provided in [user_workspaces] will override the existing workspaces in the database.
///
/// Consider using [save_user_workspace] if you only need to save a single workspace.
///
pub fn save_all_user_workspaces(
  uid: i64,
  mut conn: DBConnection,
  user_workspaces: &[UserWorkspace],
) -> FlowyResult<()> {
  let user_workspaces = user_workspaces
    .iter()
    .map(|user_workspace| UserWorkspaceTable::try_from((uid, user_workspace)))
    .collect::<Result<Vec<_>, _>>()?;

  conn.immediate_transaction(|conn| {
    let existing_ids = user_workspace_table::dsl::user_workspace_table
      .select(user_workspace_table::id)
      .load::<String>(conn)?;
    let new_ids: Vec<String> = user_workspaces.iter().map(|w| w.id.clone()).collect();
    let ids_to_delete: Vec<String> = existing_ids
      .into_iter()
      .filter(|id| !new_ids.contains(id))
      .collect();

    // insert or update the user workspaces
    for user_workspace in &user_workspaces {
      let affected_rows = diesel::update(
        user_workspace_table::dsl::user_workspace_table
          .filter(user_workspace_table::id.eq(&user_workspace.id)),
      )
      .set((
        user_workspace_table::name.eq(&user_workspace.name),
        user_workspace_table::created_at.eq(&user_workspace.created_at),
        user_workspace_table::database_storage_id.eq(&user_workspace.database_storage_id),
        user_workspace_table::icon.eq(&user_workspace.icon),
      ))
      .execute(conn)?;

      if affected_rows == 0 {
        diesel::insert_into(user_workspace_table::table)
          .values(user_workspace)
          .execute(conn)?;
      }
    }

    // delete the user workspaces that are not in the new list
    if !ids_to_delete.is_empty() {
      diesel::delete(
        user_workspace_table::dsl::user_workspace_table
          .filter(user_workspace_table::id.eq_any(ids_to_delete)),
      )
      .execute(conn)?;
    }

    Ok::<(), FlowyError>(())
  })
}

pub fn delete_user_workspaces(mut conn: DBConnection, workspace_id: &str) -> FlowyResult<()> {
  let n = conn.immediate_transaction(|conn| {
    let rows_affected: usize =
      diesel::delete(user_workspace_table::table.filter(user_workspace_table::id.eq(workspace_id)))
        .execute(conn)?;
    Ok::<usize, FlowyError>(rows_affected)
  })?;
  if n != 1 {
    warn!("expected to delete 1 row, but deleted {} rows", n);
  }
  Ok(())
}
