use anyhow::Error;
use client_api::entity::auth_dto::{UpdateUserParams, UserMetaData};
use client_api::entity::{AFRole, AFUserProfile, AFWorkspaceInvitationStatus, AFWorkspaceMember};

use flowy_user_pub::entities::{
  Authenticator, Role, UpdateUserProfileParams, UserProfile, WorkspaceInvitationStatus,
  WorkspaceMember, USER_METADATA_ICON_URL, USER_METADATA_OPEN_AI_KEY,
  USER_METADATA_STABILITY_AI_KEY,
};

use crate::af_cloud::impls::user::util::encryption_type_from_profile;

pub fn af_update_from_update_params(update: UpdateUserProfileParams) -> UpdateUserParams {
  let mut user_metadata = UserMetaData::new();
  if let Some(openai_key) = update.openai_key {
    user_metadata.insert(USER_METADATA_OPEN_AI_KEY, openai_key);
  }

  if let Some(stability_ai_key) = update.stability_ai_key {
    user_metadata.insert(USER_METADATA_STABILITY_AI_KEY, stability_ai_key);
  }

  if let Some(icon_url) = update.icon_url {
    user_metadata.insert(USER_METADATA_ICON_URL, icon_url);
  }

  UpdateUserParams {
    name: update.name,
    email: update.email,
    password: update.password,
    metadata: Some(user_metadata),
  }
}

pub fn user_profile_from_af_profile(
  token: String,
  profile: AFUserProfile,
) -> Result<UserProfile, Error> {
  let encryption_type = encryption_type_from_profile(&profile);
  let (icon_url, openai_key, stability_ai_key) = {
    profile
      .metadata
      .map(|m| {
        (
          m.get(USER_METADATA_ICON_URL)
            .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default()),
          m.get(USER_METADATA_OPEN_AI_KEY)
            .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default()),
          m.get(USER_METADATA_STABILITY_AI_KEY)
            .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default()),
        )
      })
      .unwrap_or_default()
  };

  Ok(UserProfile {
    email: profile.email.unwrap_or("".to_string()),
    name: profile.name.unwrap_or("".to_string()),
    token,
    icon_url: icon_url.unwrap_or_default(),
    openai_key: openai_key.unwrap_or_default(),
    stability_ai_key: stability_ai_key.unwrap_or_default(),
    workspace_id: profile.latest_workspace_id.to_string(),
    authenticator: Authenticator::AppFlowyCloud,
    encryption_type,
    uid: profile.uid,
    updated_at: profile.updated_at,
  })
}

pub fn to_af_role(role: Role) -> AFRole {
  match role {
    Role::Owner => AFRole::Owner,
    Role::Member => AFRole::Member,
    Role::Guest => AFRole::Guest,
  }
}

pub fn from_af_role(role: AFRole) -> Role {
  match role {
    AFRole::Owner => Role::Owner,
    AFRole::Member => Role::Member,
    AFRole::Guest => Role::Guest,
  }
}

pub fn from_af_workspace_member(member: AFWorkspaceMember) -> WorkspaceMember {
  WorkspaceMember {
    email: member.email,
    role: from_af_role(member.role),
    name: member.name,
    avatar_url: member.avatar_url,
  }
}

pub fn to_workspace_invitation_status(
  status: WorkspaceInvitationStatus,
) -> AFWorkspaceInvitationStatus {
  match status {
    WorkspaceInvitationStatus::Pending => AFWorkspaceInvitationStatus::Pending,
    WorkspaceInvitationStatus::Accepted => AFWorkspaceInvitationStatus::Accepted,
    WorkspaceInvitationStatus::Rejected => AFWorkspaceInvitationStatus::Rejected,
  }
}

pub fn from_af_workspace_invitation_status(
  status: AFWorkspaceInvitationStatus,
) -> WorkspaceInvitationStatus {
  match status {
    AFWorkspaceInvitationStatus::Pending => WorkspaceInvitationStatus::Pending,
    AFWorkspaceInvitationStatus::Accepted => WorkspaceInvitationStatus::Accepted,
    AFWorkspaceInvitationStatus::Rejected => WorkspaceInvitationStatus::Rejected,
  }
}
