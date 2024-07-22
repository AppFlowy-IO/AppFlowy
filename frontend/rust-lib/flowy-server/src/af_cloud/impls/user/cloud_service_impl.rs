use std::collections::HashMap;
use std::sync::Arc;

use anyhow::anyhow;
use client_api::entity::billing_dto::{
  SubscriptionCancelRequest, SubscriptionPlan, SubscriptionStatus, WorkspaceSubscriptionStatus,
};
use client_api::entity::workspace_dto::{
  CreateWorkspaceParam, PatchWorkspaceParam, WorkspaceMemberChangeset, WorkspaceMemberInvitation,
};
use client_api::entity::{
  AFRole, AFWorkspace, AFWorkspaceInvitation, AFWorkspaceSettings, AFWorkspaceSettingsChange,
  AuthProvider, CollabParams, CreateCollabParams, QueryWorkspaceMember,
};
use client_api::entity::{QueryCollab, QueryCollabParams};
use client_api::{Client, ClientConfiguration};
use collab_entity::{CollabObject, CollabType};
use parking_lot::RwLock;
use tracing::instrument;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams, UserUpdate, UserUpdateReceiver};
use flowy_user_pub::entities::{
  AFCloudOAuthParams, AuthResponse, Role, UpdateUserProfileParams, UserCredentials, UserProfile,
  UserWorkspace, WorkspaceInvitation, WorkspaceInvitationStatus, WorkspaceMember,
  WorkspaceSubscription, WorkspaceUsage,
};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;
use uuid::Uuid;

use crate::af_cloud::define::{ServerUser, USER_SIGN_IN_URL};
use crate::af_cloud::impls::user::dto::{
  af_update_from_update_params, from_af_workspace_member, to_af_role, user_profile_from_af_profile,
};
use crate::af_cloud::impls::user::util::encryption_type_from_profile;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::{AFCloudClient, AFServer};

use super::dto::{from_af_workspace_invitation_status, to_workspace_invitation_status};

pub(crate) struct AFCloudUserAuthServiceImpl<T> {
  server: T,
  user_change_recv: RwLock<Option<tokio::sync::mpsc::Receiver<UserUpdate>>>,
  user: Arc<dyn ServerUser>,
}

impl<T> AFCloudUserAuthServiceImpl<T> {
  pub(crate) fn new(
    server: T,
    user_change_recv: tokio::sync::mpsc::Receiver<UserUpdate>,
    user: Arc<dyn ServerUser>,
  ) -> Self {
    Self {
      server,
      user_change_recv: RwLock::new(Some(user_change_recv)),
      user,
    }
  }
}

impl<T> UserCloudService for AFCloudUserAuthServiceImpl<T>
where
  T: AFServer,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_up_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  // Zack: Not sure if this is needed anymore since sign_up handles both cases
  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = oauth_params_from_box_any(params)?;
      let resp = user_sign_in_with_url(client, params).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    // Calling the sign_out method that will revoke all connected devices' refresh tokens.
    // So do nothing here.
    FutureResult::new(async move { Ok(()) })
  }

  fn generate_sign_in_url_with_email(&self, email: &str) -> FutureResult<String, FlowyError> {
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let admin_client = get_admin_client(&client).await?;
      let action_link = admin_client.generate_sign_in_action_link(&email).await?;
      let sign_in_url = client.extract_sign_in_url(&action_link).await?;
      Ok(sign_in_url)
    })
  }

  fn create_user(&self, email: &str, password: &str) -> FutureResult<(), FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let admin_client = get_admin_client(&client).await?;
      admin_client
        .create_email_verified_user(&email, &password)
        .await?;

      Ok(())
    })
  }

  fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> FutureResult<UserProfile, FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.sign_in_password(&email, &password).await?;
      let profile = client.get_profile().await?;
      let token = client.get_token()?;
      let profile = user_profile_from_af_profile(token, profile)?;
      Ok(profile)
    })
  }

  fn sign_in_with_magic_link(
    &self,
    email: &str,
    redirect_to: &str,
  ) -> FutureResult<(), FlowyError> {
    let email = email.to_owned();
    let redirect_to = redirect_to.to_owned();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client
        .sign_in_with_magic_link(&email, Some(redirect_to))
        .await?;
      Ok(())
    })
  }

  fn generate_oauth_url_with_provider(&self, provider: &str) -> FutureResult<String, FlowyError> {
    let provider = AuthProvider::from(provider);
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let provider = provider.ok_or(anyhow!("invalid provider"))?;
      let url = try_get_client?
        .generate_oauth_url_with_provider(&provider)
        .await?;
      Ok(url)
    })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client
        .update_user(af_update_from_update_params(params))
        .await?;
      Ok(())
    })
  }

  #[instrument(level = "debug", skip_all)]
  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<UserProfile, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
      let expected_workspace_id = cloned_user.workspace_id()?;
      let client = try_get_client?;
      let profile = client.get_profile().await?;
      let token = client.get_token()?;
      let profile = user_profile_from_af_profile(token, profile)?;

      // Discard the response if the user has switched to a new workspace. This avoids updating the
      // user profile with potentially outdated information when the workspace ID no longer matches.
      check_request_workspace_id_is_match(
        &expected_workspace_id,
        &cloned_user,
        "get user profile",
      )?;
      Ok(profile)
    })
  }

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let client = try_get_client?;
      let af_workspace = client.open_workspace(&workspace_id).await?;
      Ok(to_user_workspace(af_workspace))
    })
  }

  fn get_all_workspace(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let workspaces = try_get_client?.get_workspaces().await?;
      to_user_workspaces(workspaces.0)
    })
  }

  fn invite_workspace_member(
    &self,
    invitee_email: String,
    workspace_id: String,
    role: Role,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .invite_workspace_members(
          &workspace_id,
          vec![WorkspaceMemberInvitation {
            email: invitee_email,
            role: to_af_role(role),
          }],
        )
        .await?;
      Ok(())
    })
  }

  fn list_workspace_invitations(
    &self,
    filter: Option<WorkspaceInvitationStatus>,
  ) -> FutureResult<Vec<WorkspaceInvitation>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let filter = filter.map(to_workspace_invitation_status);

    FutureResult::new(async move {
      let r = try_get_client?
        .list_workspace_invitations(filter)
        .await?
        .into_iter()
        .map(to_workspace_invitation)
        .collect();
      Ok(r)
    })
  }

  fn accept_workspace_invitations(&self, invite_id: String) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .accept_workspace_invitation(&invite_id)
        .await?;
      Ok(())
    })
  }

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .remove_workspace_members(workspace_id, vec![user_email])
        .await?;
      Ok(())
    })
  }

  fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
    role: Role,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let changeset = WorkspaceMemberChangeset::new(user_email).with_role(to_af_role(role));
      try_get_client?
        .update_workspace_member(workspace_id, changeset)
        .await?;
      Ok(())
    })
  }

  fn get_workspace_members(
    &self,
    workspace_id: String,
  ) -> FutureResult<Vec<WorkspaceMember>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let members = try_get_client?
        .get_workspace_members(&workspace_id)
        .await?
        .into_iter()
        .map(from_af_workspace_member)
        .collect();
      Ok(members)
    })
  }

  fn get_workspace_member(
    &self,
    workspace_id: String,
    uid: i64,
  ) -> FutureResult<WorkspaceMember, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let query = QueryWorkspaceMember {
        workspace_id: workspace_id.clone(),
        uid,
      };
      let member = client.get_workspace_member(query).await?;
      Ok(from_af_workspace_member(member))
    })
  }

  #[instrument(level = "debug", skip_all)]
  fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    workspace_id: &str,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.server.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id: workspace_id.clone(),
        inner: QueryCollab::new(object_id, CollabType::UserAwareness),
      };
      let resp = try_get_client?.get_collab(params).await?;
      check_request_workspace_id_is_match(
        &workspace_id,
        &cloned_user,
        "get user awareness object",
      )?;
      Ok(resp.encode_collab.doc_state.to_vec())
    })
  }

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    self.user_change_recv.write().take()
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let collab_object = collab_object.clone();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = CreateCollabParams {
        workspace_id: collab_object.workspace_id,
        object_id: collab_object.object_id,
        collab_type: collab_object.collab_type,
        encoded_collab_v1: data,
      };
      client.create_collab(params).await?;
      Ok(())
    })
  }

  fn batch_create_collab_object(
    &self,
    workspace_id: &str,
    objects: Vec<UserCollabParams>,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = objects
        .into_iter()
        .map(|object| {
          CollabParams::new(
            object.object_id,
            u8::from(object.collab_type).into(),
            object.encoded_collab,
          )
        })
        .collect::<Vec<_>>();
      try_get_client?
        .create_collab_list(&workspace_id, params)
        .await
        .map_err(FlowyError::from)?;
      Ok(())
    })
  }

  fn create_workspace(&self, workspace_name: &str) -> FutureResult<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_name_owned = workspace_name.to_owned();
    FutureResult::new(async move {
      let client = try_get_client?;
      let new_workspace = client
        .create_workspace(CreateWorkspaceParam {
          workspace_name: Some(workspace_name_owned),
        })
        .await?;
      Ok(to_user_workspace(new_workspace))
    })
  }

  fn delete_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id_owned = workspace_id.to_owned();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.delete_workspace(&workspace_id_owned).await?;
      Ok(())
    })
  }

  fn patch_workspace(
    &self,
    workspace_id: &str,
    new_workspace_name: Option<&str>,
    new_workspace_icon: Option<&str>,
  ) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let owned_workspace_id = workspace_id.to_owned();
    let owned_workspace_name = new_workspace_name.map(|s| s.to_owned());
    let owned_workspace_icon = new_workspace_icon.map(|s| s.to_owned());
    FutureResult::new(async move {
      let workspace_id: Uuid = owned_workspace_id
        .parse()
        .map_err(|_| ErrorCode::InvalidParams)?;
      let client = try_get_client?;
      client
        .patch_workspace(PatchWorkspaceParam {
          workspace_id,
          workspace_name: owned_workspace_name,
          workspace_icon: owned_workspace_icon,
        })
        .await?;
      Ok(())
    })
  }

  fn leave_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.leave_workspace(&workspace_id).await?;
      Ok(())
    })
  }

  fn subscribe_workspace(
    &self,
    workspace_id: String,
    recurring_interval: flowy_user_pub::entities::RecurringInterval,
    workspace_subscription_plan: flowy_user_pub::entities::SubscriptionPlan,
    success_url: String,
  ) -> FutureResult<String, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let subscription_plan = to_workspace_subscription_plan(workspace_subscription_plan)?;
      let client = try_get_client?;
      let payment_link = client
        .create_subscription(
          &workspace_id,
          to_recurring_interval(recurring_interval),
          subscription_plan,
          &success_url,
        )
        .await?;
      Ok(payment_link)
    })
  }

  fn get_workspace_member_info(
    &self,
    workspace_id: &str,
    uid: i64,
  ) -> FutureResult<WorkspaceMember, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = QueryWorkspaceMember {
        workspace_id: workspace_id.to_string(),
        uid,
      };
      let member = client.get_workspace_member(params).await?;
      let role = match member.role {
        AFRole::Owner => Role::Owner,
        AFRole::Member => Role::Member,
        AFRole::Guest => Role::Guest,
      };
      Ok(WorkspaceMember {
        email: member.email,
        role,
        name: member.name,
        avatar_url: member.avatar_url,
      })
    })
  }

  fn get_workspace_subscriptions(&self) -> FutureResult<Vec<WorkspaceSubscription>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let workspace_subscriptions = client
        .list_subscription()
        .await?
        .into_iter()
        .map(to_workspace_subscription)
        .collect();
      Ok(workspace_subscriptions)
    })
  }

  fn cancel_workspace_subscription(&self, workspace_id: String) -> FutureResult<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let request = SubscriptionCancelRequest {
        workspace_id,
        plan: SubscriptionPlan::Pro,
        sync: false,
        reason: Some("User requested".to_string()),
      };
      client.cancel_subscription(&request).await?;
      Ok(())
    })
  }

  fn get_workspace_usage(&self, workspace_id: String) -> FutureResult<WorkspaceUsage, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let usage = client.get_workspace_usage_and_limit(&workspace_id).await?;
      Ok(WorkspaceUsage {
        member_count: usage.member_count as usize,
        member_count_limit: usage.member_count_limit as usize,
        total_blob_bytes: usage.storage_bytes as usize,
        total_blob_bytes_limit: usage.storage_bytes_limit as usize,
      })
    })
  }

  fn get_billing_portal_url(&self) -> FutureResult<String, FlowyError> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let url = client.get_portal_session_link().await?;
      Ok(url)
    })
  }

  fn get_workspace_setting(
    &self,
    workspace_id: &str,
  ) -> FutureResult<AFWorkspaceSettings, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let settings = client.get_workspace_settings(&workspace_id).await?;
      Ok(settings)
    })
  }

  fn update_workspace_setting(
    &self,
    workspace_id: &str,
    workspace_settings: AFWorkspaceSettingsChange,
  ) -> FutureResult<AFWorkspaceSettings, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let settings = client
        .update_workspace_settings(&workspace_id, &workspace_settings)
        .await?;
      Ok(settings)
    })
  }
}

async fn get_admin_client(client: &Arc<AFCloudClient>) -> FlowyResult<Client> {
  let admin_email =
    std::env::var("GOTRUE_ADMIN_EMAIL").unwrap_or_else(|_| "admin@example.com".to_string());
  let admin_password =
    std::env::var("GOTRUE_ADMIN_PASSWORD").unwrap_or_else(|_| "password".to_string());
  let admin_client = client_api::Client::new(
    client.base_url(),
    client.ws_addr(),
    client.gotrue_url(),
    &client.device_id,
    ClientConfiguration::default(),
    &client.client_version.to_string(),
  );
  // When multiple admin_client instances attempt to sign in concurrently, multiple admin user
  // creation transaction will be created, but only the first attempt will succeed due to the
  // unique email constraint. Once the user has been created, admin_client instances can sign in
  // concurrently without issue.
  let resp = admin_client
    .sign_in_password(&admin_email, &admin_password)
    .await;
  if resp.is_err() {
    admin_client
      .sign_in_password(&admin_email, &admin_password)
      .await?;
  };
  Ok(admin_client)
}

pub async fn user_sign_up_request(
  client: Arc<AFCloudClient>,
  params: AFCloudOAuthParams,
) -> Result<AuthResponse, FlowyError> {
  user_sign_in_with_url(client, params).await
}

pub async fn user_sign_in_with_url(
  client: Arc<AFCloudClient>,
  params: AFCloudOAuthParams,
) -> Result<AuthResponse, FlowyError> {
  let is_new_user = client.sign_in_with_url(&params.sign_in_url).await?;

  let workspace_profile = client.get_user_workspace_info().await?;
  let user_profile = workspace_profile.user_profile;

  let latest_workspace = to_user_workspace(workspace_profile.visiting_workspace);
  let user_workspaces = to_user_workspaces(workspace_profile.workspaces)?;
  let encryption_type = encryption_type_from_profile(&user_profile);

  Ok(AuthResponse {
    user_id: user_profile.uid,
    user_uuid: user_profile.uuid,
    name: user_profile.name.unwrap_or_default(),
    latest_workspace,
    user_workspaces,
    email: user_profile.email,
    token: Some(client.get_token()?),
    encryption_type,
    is_new_user,
    updated_at: user_profile.updated_at,
    metadata: user_profile.metadata,
  })
}

fn to_user_workspace(af_workspace: AFWorkspace) -> UserWorkspace {
  UserWorkspace {
    id: af_workspace.workspace_id.to_string(),
    name: af_workspace.workspace_name,
    created_at: af_workspace.created_at,
    database_indexer_id: af_workspace.database_storage_id.to_string(),
    icon: af_workspace.icon,
  }
}

fn to_user_workspaces(workspaces: Vec<AFWorkspace>) -> Result<Vec<UserWorkspace>, FlowyError> {
  let mut result = Vec::with_capacity(workspaces.len());
  for item in workspaces.into_iter() {
    result.push(to_user_workspace(item));
  }
  Ok(result)
}

fn to_workspace_invitation(invi: AFWorkspaceInvitation) -> WorkspaceInvitation {
  WorkspaceInvitation {
    invite_id: invi.invite_id,
    workspace_id: invi.workspace_id,
    workspace_name: invi.workspace_name,
    inviter_email: invi.inviter_email,
    inviter_name: invi.inviter_name,
    status: from_af_workspace_invitation_status(invi.status),
    updated_at: invi.updated_at,
  }
}

fn oauth_params_from_box_any(any: BoxAny) -> Result<AFCloudOAuthParams, FlowyError> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let sign_in_url = map
    .get(USER_SIGN_IN_URL)
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing token field"))?
    .as_str();
  Ok(AFCloudOAuthParams {
    sign_in_url: sign_in_url.to_string(),
  })
}

fn to_recurring_interval(
  r: flowy_user_pub::entities::RecurringInterval,
) -> client_api::entity::billing_dto::RecurringInterval {
  match r {
    flowy_user_pub::entities::RecurringInterval::Month => {
      client_api::entity::billing_dto::RecurringInterval::Month
    },
    flowy_user_pub::entities::RecurringInterval::Year => {
      client_api::entity::billing_dto::RecurringInterval::Year
    },
  }
}

fn to_workspace_subscription_plan(
  s: flowy_user_pub::entities::SubscriptionPlan,
) -> Result<SubscriptionPlan, FlowyError> {
  match s {
    flowy_user_pub::entities::SubscriptionPlan::Pro => Ok(SubscriptionPlan::Pro),
    flowy_user_pub::entities::SubscriptionPlan::Team => Ok(SubscriptionPlan::Team),
    flowy_user_pub::entities::SubscriptionPlan::None => Err(FlowyError::new(
      ErrorCode::InvalidParams,
      "Invalid subscription plan",
    )),
  }
}

fn to_workspace_subscription(s: WorkspaceSubscriptionStatus) -> WorkspaceSubscription {
  WorkspaceSubscription {
    workspace_id: s.workspace_id,
    subscription_plan: flowy_user_pub::entities::SubscriptionPlan::None,
    recurring_interval: match s.recurring_interval {
      client_api::entity::billing_dto::RecurringInterval::Month => {
        flowy_user_pub::entities::RecurringInterval::Month
      },
      client_api::entity::billing_dto::RecurringInterval::Year => {
        flowy_user_pub::entities::RecurringInterval::Year
      },
    },
    is_active: matches!(s.subscription_status, SubscriptionStatus::Active),
    canceled_at: s.cancel_at,
  }
}
