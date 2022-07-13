use crate::entities::{
    FieldType, GridCheckboxFilter, GridDateFilter, GridNumberFilter, GridSelectOptionFilter, GridTextFilter,
};
use dashmap::DashMap;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use flowy_sync::client_grid::GridRevisionPad;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;

#[derive(Default)]
pub(crate) struct FilterResultCache {
    // key: row id
    inner: DashMap<RowId, FilterResult>,
}

impl FilterResultCache {
    pub fn new() -> Arc<Self> {
        let this = Self::default();
        Arc::new(this)
    }
}

impl std::ops::Deref for FilterResultCache {
    type Target = DashMap<String, FilterResult>;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Default)]
pub(crate) struct FilterResult {
    #[allow(dead_code)]
    pub(crate) row_index: i32,
    pub(crate) visible_by_field_id: HashMap<FilterId, bool>,
}

impl FilterResult {
    pub(crate) fn new(index: i32, _row_rev: &RowRevision) -> Self {
        Self {
            row_index: index,
            visible_by_field_id: HashMap::new(),
        }
    }

    pub(crate) fn is_visible(&self) -> bool {
        for visible in self.visible_by_field_id.values() {
            if visible == &false {
                return false;
            }
        }
        true
    }
}

#[derive(Default)]
pub(crate) struct FilterCache {
    pub(crate) text_filter: DashMap<FilterId, GridTextFilter>,
    pub(crate) url_filter: DashMap<FilterId, GridTextFilter>,
    pub(crate) number_filter: DashMap<FilterId, GridNumberFilter>,
    pub(crate) date_filter: DashMap<FilterId, GridDateFilter>,
    pub(crate) select_option_filter: DashMap<FilterId, GridSelectOptionFilter>,
    pub(crate) checkbox_filter: DashMap<FilterId, GridCheckboxFilter>,
}

impl FilterCache {
    pub(crate) async fn from_grid_pad(grid_pad: &Arc<RwLock<GridRevisionPad>>) -> Arc<Self> {
        let this = Arc::new(Self::default());
        let _ = refresh_filter_cache(this.clone(), None, grid_pad).await;
        this
    }

    pub(crate) fn remove(&self, filter_id: &FilterId) {
        let _ = match filter_id.field_type {
            FieldType::RichText => {
                let _ = self.text_filter.remove(filter_id);
            }
            FieldType::Number => {
                let _ = self.number_filter.remove(filter_id);
            }
            FieldType::DateTime => {
                let _ = self.date_filter.remove(filter_id);
            }
            FieldType::SingleSelect => {
                let _ = self.select_option_filter.remove(filter_id);
            }
            FieldType::MultiSelect => {
                let _ = self.select_option_filter.remove(filter_id);
            }
            FieldType::Checkbox => {
                let _ = self.checkbox_filter.remove(filter_id);
            }
            FieldType::URL => {
                let _ = self.url_filter.remove(filter_id);
            }
        };
    }
}

/// Refresh the filter according to the field id.
pub(crate) async fn refresh_filter_cache(
    cache: Arc<FilterCache>,
    field_ids: Option<Vec<String>>,
    grid_pad: &Arc<RwLock<GridRevisionPad>>,
) {
    let grid_pad = grid_pad.read().await;
    let filters_revs = grid_pad.get_filters(None, field_ids).unwrap_or_default();

    for filter_rev in filters_revs {
        match grid_pad.get_field_rev(&filter_rev.field_id) {
            None => {}
            Some((_, field_rev)) => {
                let filter_id = FilterId::from(field_rev);
                let field_type: FieldType = field_rev.field_type_rev.into();
                match &field_type {
                    FieldType::RichText => {
                        let _ = cache.text_filter.insert(filter_id, GridTextFilter::from(filter_rev));
                    }
                    FieldType::Number => {
                        let _ = cache
                            .number_filter
                            .insert(filter_id, GridNumberFilter::from(filter_rev));
                    }
                    FieldType::DateTime => {
                        let _ = cache.date_filter.insert(filter_id, GridDateFilter::from(filter_rev));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        let _ = cache
                            .select_option_filter
                            .insert(filter_id, GridSelectOptionFilter::from(filter_rev));
                    }
                    FieldType::Checkbox => {
                        let _ = cache
                            .checkbox_filter
                            .insert(filter_id, GridCheckboxFilter::from(filter_rev));
                    }
                    FieldType::URL => {
                        let _ = cache.url_filter.insert(filter_id, GridTextFilter::from(filter_rev));
                    }
                }
            }
        }
    }
}
#[derive(Hash, Eq, PartialEq)]
pub(crate) struct FilterId {
    pub(crate) field_id: String,
    pub(crate) field_type: FieldType,
}

impl std::convert::From<&Arc<FieldRevision>> for FilterId {
    fn from(rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: rev.id.clone(),
            field_type: rev.field_type_rev.into(),
        }
    }
}
