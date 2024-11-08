use std::collections::HashMap;
use std::sync::Arc;

use anyhow::anyhow;
use arc_swap::ArcSwapOption;
use client_api::entity::billing_dto::{
  RecurringInterval, SetSubscriptionRecurringInterval, SubscriptionCancelRequest, SubscriptionPlan,
  SubscriptionPlanDetail, WorkspaceSubscriptionStatus, WorkspaceUsageAndLimit,
};
use client_api::entity::workspace_dto::{
  CreateWorkspaceParam, PatchWorkspaceParam, QueryWorkspaceParam, WorkspaceMemberChangeset,
  WorkspaceMemberInvitation,
};
use client_api::entity::{
  AFRole, AFWorkspace, AFWorkspaceInvitation, AFWorkspaceSettings, AFWorkspaceSettingsChange,
  AuthProvider, CollabParams, CreateCollabParams, QueryWorkspaceMember,
};
use client_api::entity::{QueryCollab, QueryCollabParams};
use client_api::{Client, ClientConfiguration};
use collab_entity::{CollabObject, CollabType};
use tracing::instrument;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams, UserUpdate, UserUpdateReceiver};
use flowy_user_pub::entities::{
  AFCloudOAuthParams, AuthResponse, Role, UpdateUserProfileParams, UserCredentials, UserProfile,
  UserWorkspace, WorkspaceInvitation, WorkspaceInvitationStatus, WorkspaceMember,
};
use lib_infra::async_trait::async_trait;
use lib_infra::box_any::BoxAny;
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
  user_change_recv: ArcSwapOption<tokio::sync::mpsc::Receiver<UserUpdate>>,
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
      user_change_recv: ArcSwapOption::new(Some(Arc::new(user_change_recv))),
      user,
    }
  }
}

#[async_trait]
impl<T> UserCloudService for AFCloudUserAuthServiceImpl<T>
where
  T: AFServer,
{
  async fn sign_up(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let params = oauth_params_from_box_any(params)?;
    let resp = user_sign_up_request(try_get_client?, params).await?;
    Ok(resp)
  }

  // Zack: Not sure if this is needed anymore since sign_up handles both cases
  async fn sign_in(&self, params: BoxAny) -> Result<AuthResponse, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let params = oauth_params_from_box_any(params)?;
    let resp = user_sign_in_with_url(client, params).await?;
    Ok(resp)
  }

  async fn sign_out(&self, _token: Option<String>) -> Result<(), FlowyError> {
    // Calling the sign_out method that will revoke all connected devices' refresh tokens.
    // So do nothing here.
    Ok(())
  }

  async fn delete_account(&self) -> Result<(), FlowyError> {
    let client = self.server.try_get_client()?;
    client.delete_user().await?;
    Ok(())
  }

  async fn generate_sign_in_url_with_email(&self, email: &str) -> Result<String, FlowyError> {
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let admin_client = get_admin_client(&client).await?;
    let action_link = admin_client.generate_sign_in_action_link(&email).await?;
    let sign_in_url = client.extract_sign_in_url(&action_link).await?;
    Ok(sign_in_url)
  }

  async fn create_user(&self, email: &str, password: &str) -> Result<(), FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let admin_client = get_admin_client(&client).await?;
    admin_client
      .create_email_verified_user(&email, &password)
      .await?;

    Ok(())
  }

  async fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> Result<UserProfile, FlowyError> {
    let password = password.to_string();
    let email = email.to_string();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    client.sign_in_password(&email, &password).await?;
    let profile = client.get_profile().await?;
    let token = client.get_token()?;
    let profile = user_profile_from_af_profile(token, profile)?;
    Ok(profile)
  }

  async fn sign_in_with_magic_link(
    &self,
    email: &str,
    redirect_to: &str,
  ) -> Result<(), FlowyError> {
    let email = email.to_owned();
    let redirect_to = redirect_to.to_owned();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    client
      .sign_in_with_magic_link(&email, Some(redirect_to))
      .await?;
    Ok(())
  }

  async fn generate_oauth_url_with_provider(&self, provider: &str) -> Result<String, FlowyError> {
    let provider = AuthProvider::from(provider);
    let try_get_client = self.server.try_get_client();
    let provider = provider.ok_or(anyhow!("invalid provider"))?;
    let url = try_get_client?
      .generate_oauth_url_with_provider(&provider)
      .await?;
    Ok(url)
  }

  async fn update_user(
    &self,
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    client
      .update_user(af_update_from_update_params(params))
      .await?;
    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> Result<UserProfile, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let cloned_user = self.user.clone();
    let expected_workspace_id = cloned_user.workspace_id()?;
    let client = try_get_client?;
    let profile = client.get_profile().await?;
    let token = client.get_token()?;
    let profile = user_profile_from_af_profile(token, profile)?;

    // Discard the response if the user has switched to a new workspace. This avoids updating the
    // user profile with potentially outdated information when the workspace ID no longer matches.
    check_request_workspace_id_is_match(&expected_workspace_id, &cloned_user, "get user profile")?;
    Ok(profile)
  }

  async fn open_workspace(&self, workspace_id: &str) -> Result<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    let client = try_get_client?;
    let af_workspace = client.open_workspace(&workspace_id).await?;
    Ok(to_user_workspace(af_workspace))
  }

  async fn get_all_workspace(&self, _uid: i64) -> Result<Vec<UserWorkspace>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspaces = try_get_client?
      .get_workspaces_opt(QueryWorkspaceParam {
        include_member_count: Some(true),
      })
      .await?;
    to_user_workspaces(workspaces)
  }

  async fn create_workspace(&self, workspace_name: &str) -> Result<UserWorkspace, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_name_owned = workspace_name.to_owned();
    let client = try_get_client?;
    let new_workspace = client
      .create_workspace(CreateWorkspaceParam {
        workspace_name: Some(workspace_name_owned),
      })
      .await?;
    Ok(to_user_workspace(new_workspace))
  }

  async fn patch_workspace(
    &self,
    workspace_id: &str,
    new_workspace_name: Option<&str>,
    new_workspace_icon: Option<&str>,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let owned_workspace_id = workspace_id.to_owned();
    let owned_workspace_name = new_workspace_name.map(|s| s.to_owned());
    let owned_workspace_icon = new_workspace_icon.map(|s| s.to_owned());
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
  }

  async fn delete_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id_owned = workspace_id.to_owned();
    let client = try_get_client?;
    client.delete_workspace(&workspace_id_owned).await?;
    Ok(())
  }

  async fn invite_workspace_member(
    &self,
    invitee_email: String,
    workspace_id: String,
    role: Role,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
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
  }

  async fn list_workspace_invitations(
    &self,
    filter: Option<WorkspaceInvitationStatus>,
  ) -> Result<Vec<WorkspaceInvitation>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let filter = filter.map(to_workspace_invitation_status);

    let r = try_get_client?
      .list_workspace_invitations(filter)
      .await?
      .into_iter()
      .map(to_workspace_invitation)
      .collect();
    Ok(r)
  }

  async fn accept_workspace_invitations(&self, invite_id: String) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    try_get_client?
      .accept_workspace_invitation(&invite_id)
      .await?;
    Ok(())
  }

  async fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    try_get_client?
      .remove_workspace_members(workspace_id, vec![user_email])
      .await?;
    Ok(())
  }

  async fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
    role: Role,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let changeset = WorkspaceMemberChangeset::new(user_email).with_role(to_af_role(role));
    try_get_client?
      .update_workspace_member(workspace_id, changeset)
      .await?;
    Ok(())
  }

  async fn get_workspace_members(
    &self,
    workspace_id: String,
  ) -> Result<Vec<WorkspaceMember>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let members = try_get_client?
      .get_workspace_members(&workspace_id)
      .await?
      .into_iter()
      .map(from_af_workspace_member)
      .collect();
    Ok(members)
  }

  async fn get_workspace_member(
    &self,
    workspace_id: String,
    uid: i64,
  ) -> Result<WorkspaceMember, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let query = QueryWorkspaceMember {
      workspace_id: workspace_id.clone(),
      uid,
    };
    let member = client.get_workspace_member(query).await?;
    Ok(from_af_workspace_member(member))
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    workspace_id: &str,
    object_id: &str,
  ) -> Result<Vec<u8>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.server.try_get_client();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(object_id, CollabType::UserAwareness),
    };
    let resp = try_get_client?.get_collab(params).await?;
    check_request_workspace_id_is_match(&workspace_id, &cloned_user, "get user awareness object")?;
    Ok(resp.encode_collab.doc_state.to_vec())
  }

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    let rx = self.user_change_recv.swap(None)?;
    Arc::into_inner(rx)
  }

  async fn reset_workspace(&self, _collab_object: CollabObject) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let collab_object = collab_object.clone();
    let client = try_get_client?;
    let params = CreateCollabParams {
      workspace_id: collab_object.workspace_id,
      object_id: collab_object.object_id,
      collab_type: collab_object.collab_type,
      encoded_collab_v1: data,
    };
    client.create_collab(params).await?;
    Ok(())
  }

  async fn batch_create_collab_object(
    &self,
    workspace_id: &str,
    objects: Vec<UserCollabParams>,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
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
  }

  async fn leave_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    let client = try_get_client?;
    client.leave_workspace(&workspace_id).await?;
    Ok(())
  }

  async fn subscribe_workspace(
    &self,
    workspace_id: String,
    recurring_interval: RecurringInterval,
    subscription_plan: SubscriptionPlan,
    success_url: String,
  ) -> Result<String, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
    let client = try_get_client?;
    let payment_link = client
      .create_subscription(
        &workspace_id,
        recurring_interval,
        subscription_plan,
        &success_url,
      )
      .await?;
    Ok(payment_link)
  }

  async fn get_workspace_member_info(
    &self,
    workspace_id: &str,
    uid: i64,
  ) -> Result<WorkspaceMember, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let workspace_id = workspace_id.to_string();
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
  }

  async fn get_workspace_subscriptions(
    &self,
  ) -> Result<Vec<WorkspaceSubscriptionStatus>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let workspace_subscriptions = client.list_subscription().await?;
    Ok(workspace_subscriptions)
  }

  async fn get_workspace_subscription_one(
    &self,
    workspace_id: String,
  ) -> Result<Vec<WorkspaceSubscriptionStatus>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let workspace_subscriptions = client.get_workspace_subscriptions(&workspace_id).await?;
    Ok(workspace_subscriptions)
  }

  async fn cancel_workspace_subscription(
    &self,
    workspace_id: String,
    plan: SubscriptionPlan,
    reason: Option<String>,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    client
      .cancel_subscription(&SubscriptionCancelRequest {
        workspace_id,
        plan,
        sync: true,
        reason,
      })
      .await?;
    Ok(())
  }

  async fn get_workspace_plan(
    &self,
    workspace_id: String,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let plans = client
      .get_active_workspace_subscriptions(&workspace_id)
      .await?;
    Ok(plans)
  }

  async fn get_workspace_usage(
    &self,
    workspace_id: String,
  ) -> Result<WorkspaceUsageAndLimit, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let usage = client.get_workspace_usage_and_limit(&workspace_id).await?;
    Ok(usage)
  }

  async fn get_billing_portal_url(&self) -> Result<String, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let url = client.get_portal_session_link().await?;
    Ok(url)
  }

  async fn update_workspace_subscription_payment_period(
    &self,
    workspace_id: String,
    plan: SubscriptionPlan,
    recurring_interval: RecurringInterval,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    client
      .set_subscription_recurring_interval(&SetSubscriptionRecurringInterval {
        workspace_id,
        plan,
        recurring_interval,
      })
      .await?;
    Ok(())
  }

  async fn get_subscription_plan_details(&self) -> Result<Vec<SubscriptionPlanDetail>, FlowyError> {
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let plan_details = client.get_subscription_plan_details().await?;
    Ok(plan_details)
  }

  async fn get_workspace_setting(
    &self,
    workspace_id: &str,
  ) -> Result<AFWorkspaceSettings, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let settings = client.get_workspace_settings(&workspace_id).await?;
    Ok(settings)
  }

  async fn update_workspace_setting(
    &self,
    workspace_id: &str,
    workspace_settings: AFWorkspaceSettingsChange,
  ) -> Result<AFWorkspaceSettings, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.server.try_get_client();
    let client = try_get_client?;
    let settings = client
      .update_workspace_settings(&workspace_id, &workspace_settings)
      .await?;
    Ok(settings)
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
    workspace_database_id: af_workspace.database_storage_id.to_string(),
    icon: af_workspace.icon,
    member_count: af_workspace.member_count.unwrap_or(0),
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
