use flowy_derive::ProtoBuf;

use crate::entities::RepeatedFilterPB;
use crate::services::filter::Filter;

#[derive(Debug, Default, ProtoBuf)]
pub struct FilterChangesetNotificationPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub filters: RepeatedFilterPB,
}

impl FilterChangesetNotificationPB {
  pub fn from_filters(view_id: &str, filters: &Vec<Filter>) -> Self {
    Self {
      view_id: view_id.to_string(),
      filters: filters.into(),
    }
  }
}
