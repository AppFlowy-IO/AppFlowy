use client_api::entity::billing_dto::{
  Currency, RecurringInterval, SubscriptionPlan, SubscriptionPlanDetail,
  WorkspaceSubscriptionStatus, WorkspaceUsageAndLimit,
};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::cloud::{AFWorkspaceSettings, AFWorkspaceSettingsChange};
use flowy_user_pub::entities::{Role, WorkspaceInvitation, WorkspaceMember};
use lib_infra::validator_fn::required_not_empty_str;

#[derive(ProtoBuf, Default, Clone)]
pub struct WorkspaceMemberPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub role: AFRolePB,

  #[pb(index = 4, one_of)]
  pub avatar_url: Option<String>,
}

impl From<WorkspaceMember> for WorkspaceMemberPB {
  fn from(value: WorkspaceMember) -> Self {
    Self {
      email: value.email,
      name: value.name,
      role: value.role.into(),
      avatar_url: value.avatar_url,
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

// Deprecated
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
pub struct CancelWorkspaceSubscriptionPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub plan: SubscriptionPlanPB,

  #[pb(index = 3)]
  pub reason: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct SuccessWorkspaceSubscriptionPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub plan: SubscriptionPlanPB,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct WorkspaceMemberIdPB {
  #[pb(index = 1)]
  pub uid: i64,
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

#[derive(ProtoBuf_Enum, Clone, Default, Debug, Serialize, Deserialize)]
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

#[derive(ProtoBuf_Enum, Clone, Default, Debug, Serialize, Deserialize)]
pub enum SubscriptionPlanPB {
  #[default]
  Free = 0,
  Pro = 1,
  Team = 2,

  // Add-ons
  AiMax = 3,
  AiLocal = 4,
}

impl From<WorkspacePlanPB> for SubscriptionPlanPB {
  fn from(value: WorkspacePlanPB) -> Self {
    match value {
      WorkspacePlanPB::FreePlan => SubscriptionPlanPB::Free,
      WorkspacePlanPB::ProPlan => SubscriptionPlanPB::Pro,
      WorkspacePlanPB::TeamPlan => SubscriptionPlanPB::Team,
    }
  }
}

impl From<SubscriptionPlanPB> for SubscriptionPlan {
  fn from(value: SubscriptionPlanPB) -> Self {
    match value {
      SubscriptionPlanPB::Pro => SubscriptionPlan::Pro,
      SubscriptionPlanPB::Team => SubscriptionPlan::Team,
      SubscriptionPlanPB::Free => SubscriptionPlan::Free,
      SubscriptionPlanPB::AiMax => SubscriptionPlan::AiMax,
      SubscriptionPlanPB::AiLocal => SubscriptionPlan::AiLocal,
    }
  }
}

impl From<SubscriptionPlan> for SubscriptionPlanPB {
  fn from(value: SubscriptionPlan) -> Self {
    match value {
      SubscriptionPlan::Pro => SubscriptionPlanPB::Pro,
      SubscriptionPlan::Team => SubscriptionPlanPB::Team,
      SubscriptionPlan::Free => SubscriptionPlanPB::Free,
      SubscriptionPlan::AiMax => SubscriptionPlanPB::AiMax,
      SubscriptionPlan::AiLocal => SubscriptionPlanPB::AiLocal,
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct PaymentLinkPB {
  #[pb(index = 1)]
  pub payment_link: String,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceUsagePB {
  #[pb(index = 1)]
  pub member_count: u64,
  #[pb(index = 2)]
  pub member_count_limit: u64,
  #[pb(index = 3)]
  pub storage_bytes: u64,
  #[pb(index = 4)]
  pub storage_bytes_limit: u64,
  #[pb(index = 5)]
  pub storage_bytes_unlimited: bool,
  #[pb(index = 6)]
  pub ai_responses_count: u64,
  #[pb(index = 7)]
  pub ai_responses_count_limit: u64,
  #[pb(index = 8)]
  pub ai_responses_unlimited: bool,
  #[pb(index = 9)]
  pub local_ai: bool,
}

impl From<WorkspaceUsageAndLimit> for WorkspaceUsagePB {
  fn from(workspace_usage: WorkspaceUsageAndLimit) -> Self {
    WorkspaceUsagePB {
      member_count: workspace_usage.member_count as u64,
      member_count_limit: workspace_usage.member_count_limit as u64,
      storage_bytes: workspace_usage.storage_bytes as u64,
      storage_bytes_limit: workspace_usage.storage_bytes_limit as u64,
      storage_bytes_unlimited: workspace_usage.storage_bytes_unlimited,
      ai_responses_count: workspace_usage.ai_responses_count as u64,
      ai_responses_count_limit: workspace_usage.ai_responses_count_limit as u64,
      ai_responses_unlimited: workspace_usage.ai_responses_unlimited,
      local_ai: workspace_usage.local_ai,
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct BillingPortalPB {
  #[pb(index = 1)]
  pub url: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UseAISettingPB {
  #[pb(index = 1)]
  pub disable_search_indexing: bool,

  #[pb(index = 2)]
  pub ai_model: AIModelPB,
}

impl From<AFWorkspaceSettings> for UseAISettingPB {
  fn from(value: AFWorkspaceSettings) -> Self {
    Self {
      disable_search_indexing: value.disable_search_indexing,
      ai_model: AIModelPB::from_str(&value.ai_model).unwrap_or_default(),
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UpdateUserWorkspaceSettingPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2, one_of)]
  pub disable_search_indexing: Option<bool>,

  #[pb(index = 3, one_of)]
  pub ai_model: Option<AIModelPB>,
}

impl From<UpdateUserWorkspaceSettingPB> for AFWorkspaceSettingsChange {
  fn from(value: UpdateUserWorkspaceSettingPB) -> Self {
    let mut change = AFWorkspaceSettingsChange::new();
    if let Some(disable_search_indexing) = value.disable_search_indexing {
      change = change.disable_search_indexing(disable_search_indexing);
    }
    if let Some(ai_model) = value.ai_model {
      change = change.ai_model(ai_model.to_str().to_string());
    }
    change
  }
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Default)]
pub enum AIModelPB {
  #[default]
  DefaultModel = 0,
  GPT35 = 1,
  GPT4o = 2,
  Claude3Sonnet = 3,
  Claude3Opus = 4,
}

impl AIModelPB {
  pub fn to_str(&self) -> &str {
    match self {
      AIModelPB::DefaultModel => "default-model",
      AIModelPB::GPT35 => "gpt-3.5-turbo",
      AIModelPB::GPT4o => "gpt-4o",
      AIModelPB::Claude3Sonnet => "claude-3-sonnet",
      AIModelPB::Claude3Opus => "claude-3-opus",
    }
  }
}

impl FromStr for AIModelPB {
  type Err = anyhow::Error;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    match s {
      "gpt-3.5-turbo" => Ok(AIModelPB::GPT35),
      "gpt-4o" => Ok(AIModelPB::GPT4o),
      "claude-3-sonnet" => Ok(AIModelPB::Claude3Sonnet),
      "claude-3-opus" => Ok(AIModelPB::Claude3Opus),
      _ => Ok(AIModelPB::DefaultModel),
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceSubscriptionInfoPB {
  #[pb(index = 1)]
  pub plan: WorkspacePlanPB,
  #[pb(index = 2)]
  pub plan_subscription: WorkspaceSubscriptionV2PB, // valid if plan is not WorkspacePlanFree
  #[pb(index = 3)]
  pub add_ons: Vec<WorkspaceAddOnPB>,
}

impl WorkspaceSubscriptionInfoPB {
  pub fn default_from_workspace_id(workspace_id: String) -> Self {
    Self {
      plan: WorkspacePlanPB::FreePlan,
      plan_subscription: WorkspaceSubscriptionV2PB {
        workspace_id,
        subscription_plan: SubscriptionPlanPB::Free,
        status: WorkspaceSubscriptionStatusPB::Active,
        end_date: 0,
        interval: RecurringIntervalPB::Month,
      },
      add_ons: Vec::new(),
    }
  }
}

impl From<Vec<WorkspaceSubscriptionStatus>> for WorkspaceSubscriptionInfoPB {
  fn from(subs: Vec<WorkspaceSubscriptionStatus>) -> Self {
    let mut plan = WorkspacePlanPB::FreePlan;
    let mut plan_subscription = WorkspaceSubscriptionV2PB::default();
    let mut add_ons = Vec::new();
    for sub in subs {
      match sub.workspace_plan {
        SubscriptionPlan::Free => {
          plan = WorkspacePlanPB::FreePlan;
        },
        SubscriptionPlan::Pro => {
          plan = WorkspacePlanPB::ProPlan;
          plan_subscription = sub.into();
        },
        SubscriptionPlan::Team => {
          plan = WorkspacePlanPB::TeamPlan;
        },
        SubscriptionPlan::AiMax => {
          if plan_subscription.workspace_id.is_empty() {
            plan_subscription =
              WorkspaceSubscriptionV2PB::default_with_workspace_id(sub.workspace_id.clone());
          }

          add_ons.push(WorkspaceAddOnPB {
            type_: WorkspaceAddOnPBType::AddOnAiMax,
            add_on_subscription: sub.into(),
          });
        },
        SubscriptionPlan::AiLocal => {
          if plan_subscription.workspace_id.is_empty() {
            plan_subscription =
              WorkspaceSubscriptionV2PB::default_with_workspace_id(sub.workspace_id.clone());
          }

          add_ons.push(WorkspaceAddOnPB {
            type_: WorkspaceAddOnPBType::AddOnAiLocal,
            add_on_subscription: sub.into(),
          });
        },
      }
    }

    WorkspaceSubscriptionInfoPB {
      plan,
      plan_subscription,
      add_ons,
    }
  }
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Default)]
pub enum WorkspacePlanPB {
  #[default]
  FreePlan = 0,
  ProPlan = 1,
  TeamPlan = 2,
}

impl From<WorkspacePlanPB> for i64 {
  fn from(val: WorkspacePlanPB) -> Self {
    val as i64
  }
}

impl From<i64> for WorkspacePlanPB {
  fn from(value: i64) -> Self {
    match value {
      0 => WorkspacePlanPB::FreePlan,
      1 => WorkspacePlanPB::ProPlan,
      2 => WorkspacePlanPB::TeamPlan,
      _ => WorkspacePlanPB::FreePlan,
    }
  }
}

#[derive(Debug, ProtoBuf, Default, Clone, Serialize, Deserialize)]
pub struct WorkspaceAddOnPB {
  #[pb(index = 1)]
  type_: WorkspaceAddOnPBType,
  #[pb(index = 2)]
  add_on_subscription: WorkspaceSubscriptionV2PB,
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Default, Serialize, Deserialize)]
pub enum WorkspaceAddOnPBType {
  #[default]
  AddOnAiLocal = 0,
  AddOnAiMax = 1,
}

#[derive(Debug, ProtoBuf, Default, Clone, Serialize, Deserialize)]
pub struct WorkspaceSubscriptionV2PB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub subscription_plan: SubscriptionPlanPB,

  #[pb(index = 3)]
  pub status: WorkspaceSubscriptionStatusPB,

  #[pb(index = 4)]
  pub end_date: i64, // Unix timestamp of when this subscription cycle ends

  #[pb(index = 5)]
  pub interval: RecurringIntervalPB,
}

impl WorkspaceSubscriptionV2PB {
  pub fn default_with_workspace_id(workspace_id: String) -> Self {
    Self {
      workspace_id,
      subscription_plan: SubscriptionPlanPB::Free,
      status: WorkspaceSubscriptionStatusPB::Active,
      end_date: 0,
      interval: RecurringIntervalPB::Month,
    }
  }
}

impl From<WorkspaceSubscriptionStatus> for WorkspaceSubscriptionV2PB {
  fn from(sub: WorkspaceSubscriptionStatus) -> Self {
    Self {
      workspace_id: sub.workspace_id,
      subscription_plan: sub.workspace_plan.clone().into(),
      status: if sub.cancel_at.is_some() {
        WorkspaceSubscriptionStatusPB::Canceled
      } else {
        WorkspaceSubscriptionStatusPB::Active
      },
      interval: sub.recurring_interval.into(),
      end_date: sub.current_period_end,
    }
  }
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Default, Serialize, Deserialize)]
pub enum WorkspaceSubscriptionStatusPB {
  #[default]
  Active = 0,
  Canceled = 1,
}

impl From<WorkspaceSubscriptionStatusPB> for i64 {
  fn from(val: WorkspaceSubscriptionStatusPB) -> Self {
    val as i64
  }
}

impl From<i64> for WorkspaceSubscriptionStatusPB {
  fn from(value: i64) -> Self {
    match value {
      0 => WorkspaceSubscriptionStatusPB::Active,
      _ => WorkspaceSubscriptionStatusPB::Canceled,
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UpdateWorkspaceSubscriptionPaymentPeriodPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub plan: SubscriptionPlanPB,

  #[pb(index = 3)]
  pub recurring_interval: RecurringIntervalPB,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct RepeatedSubscriptionPlanDetailPB {
  #[pb(index = 1)]
  pub items: Vec<SubscriptionPlanDetailPB>,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct SubscriptionPlanDetailPB {
  #[pb(index = 1)]
  pub currency: CurrencyPB,
  #[pb(index = 2)]
  pub price_cents: i64,
  #[pb(index = 3)]
  pub recurring_interval: RecurringIntervalPB,
  #[pb(index = 4)]
  pub plan: SubscriptionPlanPB,
}

impl From<SubscriptionPlanDetail> for SubscriptionPlanDetailPB {
  fn from(value: SubscriptionPlanDetail) -> Self {
    Self {
      currency: value.currency.into(),
      price_cents: value.price_cents,
      recurring_interval: value.recurring_interval.into(),
      plan: value.plan.into(),
    }
  }
}

#[derive(ProtoBuf_Enum, Clone, Default)]
pub enum CurrencyPB {
  #[default]
  USD = 0,
}

impl From<Currency> for CurrencyPB {
  fn from(value: Currency) -> Self {
    match value {
      Currency::USD => CurrencyPB::USD,
    }
  }
}
