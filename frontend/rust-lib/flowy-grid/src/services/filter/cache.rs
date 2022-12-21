use crate::entities::{
    CheckboxFilterPB, ChecklistFilterPB, DateFilterPB, FieldType, NumberFilterPB, SelectOptionFilterPB, TextFilterPB,
};
use crate::services::filter::FilterType;
use std::collections::HashMap;

#[derive(Default, Debug)]
pub(crate) struct FilterMap {
    pub(crate) text_filter: HashMap<FilterType, TextFilterPB>,
    pub(crate) url_filter: HashMap<FilterType, TextFilterPB>,
    pub(crate) number_filter: HashMap<FilterType, NumberFilterPB>,
    pub(crate) date_filter: HashMap<FilterType, DateFilterPB>,
    pub(crate) select_option_filter: HashMap<FilterType, SelectOptionFilterPB>,
    pub(crate) checkbox_filter: HashMap<FilterType, CheckboxFilterPB>,
    pub(crate) checklist_filter: HashMap<FilterType, ChecklistFilterPB>,
}

impl FilterMap {
    pub(crate) fn new() -> Self {
        Self::default()
    }

    pub(crate) fn has_filter(&self, filter_type: &FilterType) -> bool {
        match filter_type.field_type {
            FieldType::RichText => self.text_filter.get(filter_type).is_some(),
            FieldType::Number => self.number_filter.get(filter_type).is_some(),
            FieldType::DateTime => self.date_filter.get(filter_type).is_some(),
            FieldType::SingleSelect => self.select_option_filter.get(filter_type).is_some(),
            FieldType::MultiSelect => self.select_option_filter.get(filter_type).is_some(),
            FieldType::Checkbox => self.checkbox_filter.get(filter_type).is_some(),
            FieldType::URL => self.url_filter.get(filter_type).is_some(),
            FieldType::Checklist => self.checklist_filter.get(filter_type).is_some(),
        }
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
        if !self.checklist_filter.is_empty() {
            return false;
        }
        true
    }

    pub(crate) fn remove(&mut self, filter_id: &FilterType) {
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
            FieldType::Checklist => {
                let _ = self.checklist_filter.remove(filter_id);
            }
        };
    }
}

/// Refresh the filter according to the field id.
#[derive(Default)]
pub(crate) struct FilterResult {
    pub(crate) visible_by_filter_id: HashMap<FilterType, bool>,
}

impl FilterResult {
    pub(crate) fn is_visible(&self) -> bool {
        let mut is_visible = true;
        for visible in self.visible_by_filter_id.values() {
            if !is_visible {
                break;
            }
            is_visible = *visible;
        }
        is_visible
    }
}
