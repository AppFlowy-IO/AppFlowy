use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::{
  RecurringInterval, Role, SubscriptionPlan, WorkspaceInvitation, WorkspaceMember,
  WorkspaceSubscription,
};
use lib_infra::validator_fn::required_not_empty_str;

#[derive(ProtoBuf, Default, Clone)]
pub struct WorkspaceMemberPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub role: AFRolePB,
}

impl From<WorkspaceMember> for WorkspaceMemberPB {
  fn from(value: WorkspaceMember) -> Self {
    Self {
      email: value.email,
      name: value.name,
      role: value.role.into(),
    }
  }
}

#[derive(ProtoBuf, Default, Clone)]
pub struct RepeatedWorkspaceMemberPB {
  #[pb(index = 1)]
  pub items: Vec<WorkspaceMemberPB>,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct WorkspaceMemberInvitationPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub invitee_email: String,

  #[pb(index = 3)]
  pub role: AFRolePB,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct RepeatedWorkspaceInvitationPB {
  #[pb(index = 1)]
  pub items: Vec<WorkspaceInvitationPB>,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceInvitationPB {
  #[pb(index = 1)]
  pub invite_id: String,
  #[pb(index = 2)]
  pub workspace_id: String,
  #[pb(index = 3)]
  pub workspace_name: String,
  #[pb(index = 4)]
  pub inviter_email: String,
  #[pb(index = 5)]
  pub inviter_name: String,
  #[pb(index = 6)]
  pub status: String,
  #[pb(index = 7)]
  pub updated_at_timestamp: i64,
}

impl From<WorkspaceInvitation> for WorkspaceInvitationPB {
  fn from(value: WorkspaceInvitation) -> Self {
    Self {
      invite_id: value.invite_id.to_string(),
      workspace_id: value.workspace_id.to_string(),
      workspace_name: value.workspace_name.unwrap_or_default(),
      inviter_email: value.inviter_email.unwrap_or_default(),
      inviter_name: value.inviter_name.unwrap_or_default(),
      status: format!("{:?}", value.status),
      updated_at_timestamp: value.updated_at.timestamp(),
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct AcceptWorkspaceInvitationPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub invite_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct AddWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct QueryWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct RemoveWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UpdateWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,

  #[pb(index = 3)]
  pub role: AFRolePB,
}

// Workspace Role
#[derive(ProtoBuf_Enum, Clone, Default)]
pub enum AFRolePB {
  Owner = 0,
  Member = 1,
  #[default]
  Guest = 2,
}

impl From<AFRolePB> for Role {
  fn from(value: AFRolePB) -> Self {
    match value {
      AFRolePB::Owner => Role::Owner,
      AFRolePB::Member => Role::Member,
      AFRolePB::Guest => Role::Guest,
    }
  }
}

impl From<Role> for AFRolePB {
  fn from(value: Role) -> Self {
    match value {
      Role::Owner => AFRolePB::Owner,
      Role::Member => AFRolePB::Member,
      Role::Guest => AFRolePB::Guest,
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UserWorkspaceIdPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct CreateWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub name: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct RenameWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub new_name: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct ChangeWorkspaceIconPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub new_icon: String,
}

#[derive(ProtoBuf, Default, Clone, Validate, Debug)]
pub struct SubscribeWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub recurring_interval: RecurringIntervalPB,

  #[pb(index = 3)]
  pub workspace_subscription_plan: SubscriptionPlanPB,

  #[pb(index = 4)]
  pub success_url: String,
}

#[derive(ProtoBuf_Enum, Clone, Default, Debug)]
pub enum RecurringIntervalPB {
  #[default]
  Month = 0,
  Year = 1,
}

impl From<RecurringIntervalPB> for RecurringInterval {
  fn from(r: RecurringIntervalPB) -> Self {
    match r {
      RecurringIntervalPB::Month => RecurringInterval::Month,
      RecurringIntervalPB::Year => RecurringInterval::Year,
    }
  }
}

impl From<RecurringInterval> for RecurringIntervalPB {
  fn from(r: RecurringInterval) -> Self {
    match r {
      RecurringInterval::Month => RecurringIntervalPB::Month,
      RecurringInterval::Year => RecurringIntervalPB::Year,
    }
  }
}

#[derive(ProtoBuf_Enum, Clone, Default, Debug)]
pub enum SubscriptionPlanPB {
  #[default]
  None = 0,
  Pro = 1,
  Team = 2,
}

impl From<SubscriptionPlanPB> for SubscriptionPlan {
  fn from(value: SubscriptionPlanPB) -> Self {
    match value {
      SubscriptionPlanPB::Pro => SubscriptionPlan::Pro,
      SubscriptionPlanPB::Team => SubscriptionPlan::Team,
      SubscriptionPlanPB::None => SubscriptionPlan::None,
    }
  }
}

impl From<SubscriptionPlan> for SubscriptionPlanPB {
  fn from(value: SubscriptionPlan) -> Self {
    match value {
      SubscriptionPlan::Pro => SubscriptionPlanPB::Pro,
      SubscriptionPlan::Team => SubscriptionPlanPB::Team,
      SubscriptionPlan::None => SubscriptionPlanPB::None,
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct PaymentLinkPB {
  #[pb(index = 1)]
  pub payment_link: String,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct RepeatedWorkspaceSubscriptionPB {
  #[pb(index = 1)]
  pub items: Vec<WorkspaceSubscriptionPB>,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceSubscriptionPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub subscription_plan: SubscriptionPlanPB,

  #[pb(index = 3)]
  pub recurring_interval: RecurringIntervalPB,

  #[pb(index = 4)]
  pub is_active: bool,
}

impl From<WorkspaceSubscription> for WorkspaceSubscriptionPB {
  fn from(s: WorkspaceSubscription) -> Self {
    Self {
      workspace_id: s.workspace_id,
      subscription_plan: s.subscription_plan.into(),
      recurring_interval: s.recurring_interval.into(),
      is_active: s.is_active,
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceUsagePB {
  #[pb(index = 1)]
  pub member_count: u64,
  #[pb(index = 2)]
  pub member_count_limit: u64,
  #[pb(index = 3)]
  pub total_blob_bytes: u64,
  #[pb(index = 4)]
  pub total_blob_bytes_limit: u64,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct BillingPortalPB {
  #[pb(index = 1)]
  pub url: String,
}
