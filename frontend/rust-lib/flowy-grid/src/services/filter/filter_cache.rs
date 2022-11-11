use crate::entities::{
    CheckboxFilterConfigurationPB, DateFilterConfigurationPB, FieldType, NumberFilterConfigurationPB,
    SelectOptionFilterConfigurationPB, TextFilterConfigurationPB,
};
use crate::services::filter::FilterId;

use grid_rev_model::RowRevision;
use std::collections::HashMap;

#[derive(Default)]
pub(crate) struct FilterMap {
    pub(crate) text_filter: HashMap<FilterId, TextFilterConfigurationPB>,
    pub(crate) url_filter: HashMap<FilterId, TextFilterConfigurationPB>,
    pub(crate) number_filter: HashMap<FilterId, NumberFilterConfigurationPB>,
    pub(crate) date_filter: HashMap<FilterId, DateFilterConfigurationPB>,
    pub(crate) select_option_filter: HashMap<FilterId, SelectOptionFilterConfigurationPB>,
    pub(crate) checkbox_filter: HashMap<FilterId, CheckboxFilterConfigurationPB>,
}

impl FilterMap {
    pub(crate) fn new() -> Self {
        Self::default()
    }

    pub(crate) fn remove(&mut self, filter_id: &FilterId) {
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
