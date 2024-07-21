use crate::services::authenticate_user::AuthenticateUser;
use client_api::entity::billing_dto::SubscriptionPlan;
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::cloud::UserCloudServiceProvider;
use std::sync::Weak;
use std::time::Duration;

/// `PeriodicallyCheckBillingState` is designed to periodically verify the subscription
/// plan of a given workspace. It utilizes a cloud service provider to fetch the current
/// subscription plans and compares them with an expected plan.
///
/// If the expected plan is found, the check stops. Otherwise, it continues to check
/// at specified intervals until the expected plan is found or the maximum number of
/// attempts is reached.
pub struct PeriodicallyCheckBillingState {
  workspace_id: String,
  cloud_service: Weak<dyn UserCloudServiceProvider>,
  expected_plan: SubscriptionPlan,
  user: Weak<AuthenticateUser>,
}

impl PeriodicallyCheckBillingState {
  pub fn new(
    workspace_id: String,
    expected_plan: SubscriptionPlan,
    cloud_service: Weak<dyn UserCloudServiceProvider>,
    user: Weak<AuthenticateUser>,
  ) -> Self {
    Self {
      workspace_id,
      cloud_service,
      expected_plan,
      user,
    }
  }

  pub async fn start(&self) -> FlowyResult<Vec<SubscriptionPlan>> {
    let cloud_service = self
      .cloud_service
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Cloud service is not available"))?;

    let mut attempts = 0;
    let max_attempts = 5;
    let delay_duration = Duration::from_secs(4);
    while attempts < max_attempts {
      let plans = cloud_service
        .get_user_service()?
        .get_workspace_plan(self.workspace_id.clone())
        .await?;

      if plans.contains(&self.expected_plan) {
        return Ok(plans);
      }

      attempts += 1;
      tokio::time::sleep(delay_duration).await;

      if let Some(user) = self.user.upgrade() {
        if let Ok(current_workspace_id) = user.workspace_id() {
          if current_workspace_id != self.workspace_id {
            return Err(
              FlowyError::internal()
                .with_context("Workspace ID has changed while checking the billing state"),
            );
          }
        } else {
          break;
        }
      }
    }

    Err(
      FlowyError::response_timeout()
        .with_context("Exceeded maximum number of checks without finding the expected plan"),
    )
  }
}
