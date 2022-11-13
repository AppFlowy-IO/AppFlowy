use crate::entities::{CheckboxFilterPB, DateFilterPB, FieldType, NumberFilterPB, SelectOptionFilterPB, TextFilterPB};
use crate::services::filter::FilterId;

use std::collections::HashMap;

#[derive(Default)]
pub(crate) struct FilterMap {
    pub(crate) text_filter: HashMap<FilterId, TextFilterPB>,
    pub(crate) url_filter: HashMap<FilterId, TextFilterPB>,
    pub(crate) number_filter: HashMap<FilterId, NumberFilterPB>,
    pub(crate) date_filter: HashMap<FilterId, DateFilterPB>,
    pub(crate) select_option_filter: HashMap<FilterId, SelectOptionFilterPB>,
    pub(crate) checkbox_filter: HashMap<FilterId, CheckboxFilterPB>,
}

impl FilterMap {
    pub(crate) fn new() -> Self {
        Self::default()
    }

    pub(crate) fn is_empty(&self) -> bool {
        if !self.text_filter.is_empty() {
            return false;
        }

        if !self.url_filter.is_empty() {
            return false;
        }

        if !self.number_filter.is_empty() {
            return false;
        }

        if !self.number_filter.is_empty() {
            return false;
        }

        if !self.date_filter.is_empty() {
            return false;
        }

        if !self.select_option_filter.is_empty() {
            return false;
        }

        if !self.checkbox_filter.is_empty() {
            return false;
        }
        true
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
    pub(crate) visible_by_filter_id: HashMap<FilterId, bool>,
}

impl FilterResult {
    pub(crate) fn is_visible(&self) -> bool {
        for visible in self.visible_by_filter_id.values() {
            if visible == &false {
                return false;
            }
        }
        true
    }
}
