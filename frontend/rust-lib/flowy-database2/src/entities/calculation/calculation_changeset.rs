use flowy_derive::ProtoBuf;

use super::{CalculationPB, CalculationType};

use lib_infra::validator_fn::required_not_empty_str;
use validator::Validate;

#[derive(Default, ProtoBuf, Validate)]
pub struct UpdateCalculationChangesetPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub calculation_id: Option<String>,

  #[pb(index = 3)]
  #[validate(custom = "required_not_empty_str")]
  pub field_id: String,

  #[pb(index = 4)]
  pub calculation_type: CalculationType,
}

#[derive(Default, ProtoBuf, Validate)]
pub struct RemoveCalculationChangesetPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub view_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub field_id: String,

  #[pb(index = 3)]
  #[validate(custom = "required_not_empty_str")]
  pub calculation_id: String,
}

#[derive(Debug, Default, ProtoBuf, Clone)]
pub struct CalculationChangesetNotificationPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub insert_calculations: Vec<CalculationPB>,

  #[pb(index = 3)]
  pub update_calculations: Vec<CalculationPB>,

  #[pb(index = 4)]
  pub delete_calculations: Vec<CalculationPB>,
}

impl CalculationChangesetNotificationPB {
  pub fn from_insert(view_id: &str, calculations: Vec<CalculationPB>) -> Self {
    Self {
      view_id: view_id.to_string(),
      insert_calculations: calculations,
      delete_calculations: Default::default(),
      update_calculations: Default::default(),
    }
  }
  pub fn from_delete(view_id: &str, calculations: Vec<CalculationPB>) -> Self {
    Self {
      view_id: view_id.to_string(),
      insert_calculations: Default::default(),
      delete_calculations: calculations,
      update_calculations: Default::default(),
    }
  }

  pub fn from_update(view_id: &str, calculations: Vec<CalculationPB>) -> Self {
    Self {
      view_id: view_id.to_string(),
      insert_calculations: Default::default(),
      delete_calculations: Default::default(),
      update_calculations: calculations,
    }
  }
}
