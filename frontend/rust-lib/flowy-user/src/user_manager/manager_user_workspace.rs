use chrono::{Duration, NaiveDateTime, Utc};
use client_api::entity::billing_dto::{RecurringInterval, SubscriptionPlanDetail};
use client_api::entity::billing_dto::{SubscriptionPlan, WorkspaceUsageAndLimit};

use std::str::FromStr;
use std::sync::Arc;

use crate::entities::{
  RepeatedUserWorkspacePB, SubscribeWorkspacePB, SuccessWorkspaceSubscriptionPB,
  UpdateUserWorkspaceSettingPB, UserWorkspacePB, WorkspaceSettingsPB, WorkspaceSubscriptionInfoPB,
};
use crate::migrations::AnonUser;
use crate::notification::{send_notification, UserNotification};
use crate::services::billing_check::PeriodicallyCheckBillingState;
use crate::services::data_import::{
  generate_import_data, upload_collab_objects_data, ImportedFolder, ImportedSource,
};

use crate::user_manager::UserManager;
use collab_integrate::CollabKVDB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_pub::entities::{ImportFrom, ImportedCollabData, ImportedFolderData};
use flowy_sqlite::ConnectionPool;
use flowy_user_pub::cloud::{UserCloudService, UserCloudServiceProvider};
use flowy_user_pub::entities::{
  AuthType, Role, UserWorkspace, WorkspaceInvitation, WorkspaceInvitationStatus, WorkspaceMember,
};
use flowy_user_pub::session::Session;
use flowy_user_pub::sql::*;
use tracing::{error, info, instrument, trace};
use uuid::Uuid;

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
      generate_import_data(&cloned_current_session, &user_collab_db, imported_folder)
        .map_err(|err| FlowyError::new(ErrorCode::AppFlowyDataFolderImportError, err.to_string()))
    })
    .await??;

    info!(
      "[AppflowyData]: upload {} document, {} database, {}, rows",
      import_data.collab_data.document_object_ids.len(),
      import_data.collab_data.database_object_ids.len(),
      import_data.collab_data.row_object_ids.len()
    );
    self
      .upload_collab_data(&current_session, import_data.collab_data)
      .await?;

    self
      .upload_folder_data(
        &current_session,
        &import_data.source,
        import_data.parent_view_id,
        import_data.folder_data,
      )
      .await?;

    Ok(())
  }

  async fn upload_folder_data(
    &self,
    _current_session: &Session,
    source: &ImportFrom,
    parent_view_id: Option<String>,
    folder_data: ImportedFolderData,
  ) -> Result<(), FlowyError> {
    let ImportedFolderData {
      views,
      orphan_views,
      database_view_ids_by_database_id,
    } = folder_data;
    self
      .user_workspace_service
      .import_database_views(database_view_ids_by_database_id)
      .await?;
    self
      .user_workspace_service
      .import_views(source, views, orphan_views, parent_view_id)
      .await?;

    Ok(())
  }

  async fn upload_collab_data(
    &self,
    current_session: &Session,
    collab_data: ImportedCollabData,
  ) -> Result<(), FlowyError> {
    let user = self
      .get_user_profile_from_disk(current_session.user_id, &current_session.workspace_id)
      .await?;
    let user_collab_db = self
      .get_collab_db(current_session.user_id)?
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Collab db not found"))?;

    let user_id = current_session.user_id;
    let workspace_id = Uuid::parse_str(&current_session.workspace_id)?;
    let weak_user_collab_db = Arc::downgrade(&user_collab_db);
    let weak_user_cloud_service = self.cloud_service.get_user_service()?;
    match upload_collab_objects_data(
      user_id,
      weak_user_collab_db,
      &workspace_id,
      &user.workspace_auth_type,
      collab_data,
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
      imported_session: old_user.session.as_ref().clone(),
      imported_collab_db: old_collab_db.clone(),
      container_name: None,
      parent_view_id: None,
      source: ImportedSource::AnonUser,
      workspace_database_id: "".to_string(),
    };
    self.perform_import(import_context).await?;
    Ok(())
  }

  #[instrument(skip(self), err)]
  pub async fn open_workspace(&self, workspace_id: &Uuid, auth_type: AuthType) -> FlowyResult<()> {
    info!("open workspace: {}, auth type:{}", workspace_id, auth_type);
    let workspace_id_str = workspace_id.to_string();
    let token = self.token_from_auth_type(&auth_type)?;
    self.cloud_service.set_server_auth_type(&auth_type, token)?;

    let uid = self.user_id()?;
    let profile = self
      .get_user_profile_from_disk(uid, &workspace_id_str)
      .await?;
    if let Err(err) = self.cloud_service.set_token(&profile.token) {
      error!("Set token failed: {}", err);
    }

    let mut conn = self.db_connection(self.user_id()?)?;
    let user_workspace = match select_user_workspace(&workspace_id_str, &mut conn) {
      Err(err) => {
        if err.is_record_not_found() {
          sync_workspace(
            workspace_id,
            self.cloud_service.get_user_service()?,
            uid,
            auth_type,
            self.db_pool(uid)?,
          )
          .await?
        } else {
          return Err(err);
        }
      },
      Ok(row) => {
        let user_workspace = UserWorkspace::from(row);
        let workspace_id = *workspace_id;
        let user_service = self.cloud_service.get_user_service()?;
        let pool = self.db_pool(uid)?;
        tokio::spawn(async move {
          let _ = sync_workspace(&workspace_id, user_service, uid, auth_type, pool).await;
        });
        user_workspace
      },
    };

    self
      .authenticate_user
      .set_user_workspace(user_workspace.clone())?;

    let uid = self.user_id()?;
    if let Err(err) = self
      .user_status_callback
      .read()
      .await
      .on_workspace_opened(uid, workspace_id, &user_workspace, &auth_type)
      .await
    {
      error!("Open workspace failed: {:?}", err);
    }

    if let Err(err) = self
      .initial_user_awareness(self.get_session()?.as_ref(), &auth_type)
      .await
    {
      error!(
        "Failed to initialize user awareness when opening workspace: {:?}",
        err
      );
    }

    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn create_workspace(
    &self,
    workspace_name: &str,
    auth_type: AuthType,
  ) -> FlowyResult<UserWorkspace> {
    let token = self.token_from_auth_type(&auth_type)?;
    self.cloud_service.set_server_auth_type(&auth_type, token)?;

    let new_workspace = self
      .cloud_service
      .get_user_service()?
      .create_workspace(workspace_name)
      .await?;

    info!(
      "create workspace: {}, name:{}, auth_type: {}",
      new_workspace.id, new_workspace.name, auth_type
    );

    // save the workspace to sqlite db
    let uid = self.user_id()?;
    let mut conn = self.db_connection(uid)?;
    upsert_user_workspace(uid, auth_type, new_workspace.clone(), &mut conn)?;
    Ok(new_workspace)
  }

  pub async fn patch_workspace(
    &self,
    workspace_id: &Uuid,
    changeset: UserWorkspaceChangeset,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .patch_workspace(workspace_id, changeset.name.clone(), changeset.icon.clone())
      .await?;

    // save the icon and name to sqlite db
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    update_user_workspace(conn, changeset)?;

    let row = self.get_user_workspace_from_db(uid, workspace_id)?;
    let payload = UserWorkspacePB::from(row);
    send_notification(&uid.to_string(), UserNotification::DidUpdateUserWorkspace)
      .payload(payload)
      .send();

    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn leave_workspace(&self, workspace_id: &Uuid) -> FlowyResult<()> {
    info!("leave workspace: {}", workspace_id);
    self
      .cloud_service
      .get_user_service()?
      .leave_workspace(workspace_id)
      .await?;

    // delete workspace from local sqlite db
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    delete_user_workspace(conn, workspace_id.to_string().as_str())?;

    self
      .user_workspace_service
      .did_delete_workspace(workspace_id)
      .await
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn delete_workspace(&self, workspace_id: &Uuid) -> FlowyResult<()> {
    info!("delete workspace: {}", workspace_id);
    self
      .cloud_service
      .get_user_service()?
      .delete_workspace(workspace_id)
      .await?;
    let uid = self.user_id()?;
    let conn = self.db_connection(uid)?;
    delete_user_workspace(conn, workspace_id.to_string().as_str())?;

    self
      .user_workspace_service
      .did_delete_workspace(workspace_id)
      .await?;

    Ok(())
  }

  pub async fn invite_member_to_workspace(
    &self,
    workspace_id: Uuid,
    invitee_email: String,
    role: Role,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .invite_workspace_member(invitee_email, workspace_id, role)
      .await?;
    Ok(())
  }

  pub async fn list_pending_workspace_invitations(&self) -> FlowyResult<Vec<WorkspaceInvitation>> {
    let status = Some(WorkspaceInvitationStatus::Pending);
    let invitations = self
      .cloud_service
      .get_user_service()?
      .list_workspace_invitations(status)
      .await?;
    Ok(invitations)
  }

  pub async fn accept_workspace_invitation(&self, invite_id: String) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .accept_workspace_invitations(invite_id)
      .await?;
    Ok(())
  }

  pub async fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: Uuid,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .remove_workspace_member(user_email, workspace_id)
      .await?;
    Ok(())
  }

  pub async fn get_workspace_members(
    &self,
    workspace_id: Uuid,
  ) -> FlowyResult<Vec<WorkspaceMember>> {
    let members = self
      .cloud_service
      .get_user_service()?
      .get_workspace_members(workspace_id)
      .await?;
    Ok(members)
  }

  pub async fn get_workspace_member(
    &self,
    workspace_id: Uuid,
    uid: i64,
  ) -> FlowyResult<WorkspaceMember> {
    let member = self
      .cloud_service
      .get_user_service()?
      .get_workspace_member(&workspace_id, uid)
      .await?;
    Ok(member)
  }

  pub async fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: Uuid,
    role: Role,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .update_workspace_member(user_email, workspace_id, role)
      .await?;
    Ok(())
  }

  pub fn get_user_workspace_from_db(
    &self,
    uid: i64,
    workspace_id: &Uuid,
  ) -> FlowyResult<UserWorkspaceTable> {
    let mut conn = self.db_connection(uid)?;
    select_user_workspace(workspace_id.to_string().as_str(), &mut conn)
  }

  pub async fn get_all_user_workspaces(
    &self,
    uid: i64,
    auth_type: AuthType,
  ) -> FlowyResult<Vec<UserWorkspace>> {
    // 1) Load & return the local copy immediately
    let mut conn = self.db_connection(uid)?;
    let local_workspaces = select_all_user_workspace(uid, &mut conn)?;

    // 2) If both cloud service and pool are available, fire off a background sync
    if let (Ok(service), Ok(pool)) = (self.cloud_service.get_user_service(), self.db_pool(uid)) {
      // capture only what we need
      let auth_copy = auth_type;

      tokio::spawn(async move {
        // fetch remote list
        let new_ws = match service.get_all_workspace(uid).await {
          Ok(ws) => ws,
          Err(e) => {
            trace!("failed to fetch remote workspaces for {}: {:?}", uid, e);
            return;
          },
        };

        // get a pooled DB connection
        let mut conn = match pool.get() {
          Ok(c) => c,
          Err(e) => {
            trace!("failed to get DB connection for {}: {:?}", uid, e);
            return;
          },
        };

        // sync + diff
        match sync_user_workspaces_with_diff(uid, auth_copy, &new_ws, &mut conn) {
          Ok(changes) if !changes.is_empty() => {
            info!(
              "synced {} workspaces for user {} and auth type {:?}. changes: {:?}",
              changes.len(),
              uid,
              auth_copy,
              changes
            );
            // only send notification if there were real changes
            if let Ok(updated_list) = select_all_user_workspace(uid, &mut conn) {
              let repeated_pb = RepeatedUserWorkspacePB::from(updated_list);
              send_notification(&uid.to_string(), UserNotification::DidUpdateUserWorkspaces)
                .payload(repeated_pb)
                .send();
            }
          },
          Ok(_) => trace!("no workspaces updated for {}", uid),
          Err(e) => trace!("sync error for {}: {:?}", uid, e),
        }
      });
    }

    Ok(local_workspaces)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn subscribe_workspace(
    &self,
    workspace_subscription: SubscribeWorkspacePB,
  ) -> FlowyResult<String> {
    let workspace_id = Uuid::from_str(&workspace_subscription.workspace_id)?;
    let payment_link = self
      .cloud_service
      .get_user_service()?
      .subscribe_workspace(
        workspace_id,
        workspace_subscription.recurring_interval.into(),
        workspace_subscription.workspace_subscription_plan.into(),
        workspace_subscription.success_url,
      )
      .await?;

    Ok(payment_link)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn get_workspace_subscription_info(
    &self,
    workspace_id: String,
  ) -> FlowyResult<WorkspaceSubscriptionInfoPB> {
    let workspace_id = Uuid::from_str(&workspace_id)?;
    let subscriptions = self
      .cloud_service
      .get_user_service()?
      .get_workspace_subscription_one(&workspace_id)
      .await?;

    Ok(WorkspaceSubscriptionInfoPB::from(subscriptions))
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn cancel_workspace_subscription(
    &self,
    workspace_id: String,
    plan: SubscriptionPlan,
    reason: Option<String>,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .cancel_workspace_subscription(workspace_id, plan, reason)
      .await?;
    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn update_workspace_subscription_payment_period(
    &self,
    workspace_id: &Uuid,
    plan: SubscriptionPlan,
    recurring_interval: RecurringInterval,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .get_user_service()?
      .update_workspace_subscription_payment_period(workspace_id, plan, recurring_interval)
      .await?;
    Ok(())
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn get_subscription_plan_details(&self) -> FlowyResult<Vec<SubscriptionPlanDetail>> {
    let plan_details = self
      .cloud_service
      .get_user_service()?
      .get_subscription_plan_details()
      .await?;
    Ok(plan_details)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn get_workspace_usage(
    &self,
    workspace_id: &Uuid,
  ) -> FlowyResult<WorkspaceUsageAndLimit> {
    let workspace_usage = self
      .cloud_service
      .get_user_service()?
      .get_workspace_usage(workspace_id)
      .await?;

    // Check if the current workspace storage is not unlimited. If it is not unlimited,
    // verify whether the storage bytes exceed the storage limit.
    // If the storage is unlimited, allow writing. Otherwise, allow writing only if
    // the storage bytes are less than the storage limit.
    let can_write = if workspace_usage.storage_bytes_unlimited {
      true
    } else {
      workspace_usage.storage_bytes < workspace_usage.storage_bytes_limit
    };
    self
      .user_status_callback
      .read()
      .await
      .on_storage_permission_updated(can_write);

    Ok(workspace_usage)
  }

  #[instrument(level = "info", skip(self), err)]
  pub async fn get_billing_portal_url(&self) -> FlowyResult<String> {
    let url = self
      .cloud_service
      .get_user_service()?
      .get_billing_portal_url()
      .await?;
    Ok(url)
  }

  pub async fn update_workspace_setting(
    &self,
    updated_settings: UpdateUserWorkspaceSettingPB,
  ) -> FlowyResult<()> {
    let workspace_id = Uuid::from_str(&updated_settings.workspace_id)?;
    let cloud_service = self.cloud_service.get_user_service()?;
    let settings = cloud_service
      .update_workspace_setting(&workspace_id, updated_settings.clone().into())
      .await?;

    let changeset = WorkspaceSettingsChangeset {
      id: workspace_id.to_string(),
      disable_search_indexing: updated_settings.disable_search_indexing,
      ai_model: updated_settings.ai_model.clone(),
    };

    let uid = self.user_id()?;
    let mut conn = self.db_connection(uid)?;
    update_workspace_setting(&mut conn, changeset)?;

    let pb = WorkspaceSettingsPB::from(&settings);
    send_notification(
      &uid.to_string(),
      UserNotification::DidUpdateWorkspaceSetting,
    )
    .payload(pb)
    .send();
    Ok(())
  }

  pub async fn get_workspace_settings(
    &self,
    workspace_id: &Uuid,
  ) -> FlowyResult<WorkspaceSettingsPB> {
    let uid = self.user_id()?;
    let mut conn = self.db_connection(uid)?;
    match select_workspace_setting(&mut conn, &workspace_id.to_string()) {
      Ok(workspace_settings) => {
        trace!("workspace settings found in local db");
        let pb = WorkspaceSettingsPB::from(workspace_settings);
        let old_pb = pb.clone();
        let workspace_id = *workspace_id;

        // Spawn a task to sync remote settings using the helper
        let pool = self.db_pool(uid)?;
        let cloud_service = self.cloud_service.clone();
        tokio::spawn(async move {
          let _ = sync_workspace_settings(cloud_service, workspace_id, old_pb, uid, pool).await;
        });
        Ok(pb)
      },
      Err(err) => {
        if err.is_record_not_found() {
          trace!("No workspace settings found, fetch from remote");
          let service = self.cloud_service.get_user_service()?;
          let settings = service.get_workspace_setting(workspace_id).await?;
          let pb = WorkspaceSettingsPB::from(&settings);
          let mut conn = self.db_connection(uid)?;
          upsert_workspace_setting(
            &mut conn,
            WorkspaceSettingsTable::from_workspace_settings(workspace_id, &settings),
          )?;
          Ok(pb)
        } else {
          Err(err)
        }
      },
    }
  }

  pub async fn get_workspace_member_info(
    &self,
    uid: i64,
    workspace_id: &Uuid,
  ) -> FlowyResult<WorkspaceMember> {
    let db = self.authenticate_user.get_sqlite_connection(uid)?;
    // Can opt in using memory cache
    if let Ok(member_record) = select_workspace_member(db, &workspace_id.to_string(), uid) {
      if is_older_than_n_minutes(member_record.updated_at, 10) {
        self
          .get_workspace_member_info_from_remote(workspace_id, uid)
          .await?;
      }

      return Ok(WorkspaceMember {
        email: member_record.email,
        role: member_record.role.into(),
        name: member_record.name,
        avatar_url: member_record.avatar_url,
        joined_at: member_record.joined_at,
      });
    }

    let member = self
      .get_workspace_member_info_from_remote(workspace_id, uid)
      .await?;

    Ok(member)
  }

  async fn get_workspace_member_info_from_remote(
    &self,
    workspace_id: &Uuid,
    uid: i64,
  ) -> FlowyResult<WorkspaceMember> {
    trace!("get workspace member info from remote: {}", workspace_id);
    let member = self
      .cloud_service
      .get_user_service()?
      .get_workspace_member(workspace_id, uid)
      .await?;

    let record = WorkspaceMemberTable {
      email: member.email.clone(),
      role: member.role.into(),
      name: member.name.clone(),
      avatar_url: member.avatar_url.clone(),
      uid,
      workspace_id: workspace_id.to_string(),
      updated_at: Utc::now().naive_utc(),
      joined_at: member.joined_at,
    };

    let mut db = self.authenticate_user.get_sqlite_connection(uid)?;
    upsert_workspace_member(&mut db, record)?;
    Ok(member)
  }

  pub async fn notify_did_switch_plan(
    &self,
    success: SuccessWorkspaceSubscriptionPB,
  ) -> FlowyResult<()> {
    // periodically check the billing state
    let workspace_id = Uuid::from_str(&success.workspace_id)?;
    let plans = PeriodicallyCheckBillingState::new(
      workspace_id,
      success.plan.map(SubscriptionPlan::from),
      Arc::downgrade(&self.cloud_service),
      Arc::downgrade(&self.authenticate_user),
    )
    .start()
    .await?;

    trace!("Current plans: {:?}", plans);
    self
      .user_status_callback
      .read()
      .await
      .on_subscription_plans_updated(plans);
    Ok(())
  }
}

fn is_older_than_n_minutes(updated_at: NaiveDateTime, minutes: i64) -> bool {
  let current_time: NaiveDateTime = Utc::now().naive_utc();
  match current_time.checked_sub_signed(Duration::minutes(minutes)) {
    Some(five_minutes_ago) => updated_at < five_minutes_ago,
    None => false,
  }
}

async fn sync_workspace_settings(
  cloud_service: Arc<dyn UserCloudServiceProvider>,
  workspace_id: Uuid,
  old_pb: WorkspaceSettingsPB,
  uid: i64,
  pool: Arc<ConnectionPool>,
) -> FlowyResult<()> {
  let service = cloud_service.get_user_service()?;
  let settings = service.get_workspace_setting(&workspace_id).await?;
  let new_pb = WorkspaceSettingsPB::from(&settings);
  if new_pb != old_pb {
    trace!("workspace settings updated");
    send_notification(
      &uid.to_string(),
      UserNotification::DidUpdateWorkspaceSetting,
    )
    .payload(new_pb)
    .send();
    if let Ok(mut conn) = pool.get() {
      upsert_workspace_setting(
        &mut conn,
        WorkspaceSettingsTable::from_workspace_settings(&workspace_id, &settings),
      )?;
    }
  }
  Ok(())
}

async fn sync_workspace(
  workspace_id: &Uuid,
  user_service: Arc<dyn UserCloudService>,
  uid: i64,
  auth_type: AuthType,
  pool: Arc<ConnectionPool>,
) -> FlowyResult<UserWorkspace> {
  let user_workspace = user_service.open_workspace(workspace_id).await?;
  if let Ok(mut conn) = pool.get() {
    upsert_user_workspace(uid, auth_type, user_workspace.clone(), &mut conn)?;
  }
  Ok(user_workspace)
}
