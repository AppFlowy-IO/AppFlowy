use crate::entities::{FilterPB, InsertedRowPB, RepeatedFilterPB, RowPB};
use flowy_derive::ProtoBuf;

#[derive(Debug, Default, ProtoBuf)]
pub struct FilterChangesetNotificationPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub insert_filters: Vec<FilterPB>,

    #[pb(index = 3)]
    pub delete_filters: Vec<FilterPB>,
}

impl FilterChangesetNotificationPB {
    pub fn from_insert(view_id: &str, filters: Vec<FilterPB>) -> Self {
        Self {
            view_id: view_id.to_string(),
            insert_filters: filters,
            delete_filters: Default::default(),
        }
    }
    pub fn from_delete(view_id: &str, filters: Vec<FilterPB>) -> Self {
        Self {
            view_id: view_id.to_string(),
            insert_filters: Default::default(),
            delete_filters: filters,
        }
    }
}
