use flowy_grid::entities::FieldType;
use std::sync::Arc;

use flowy_grid::services::field::{
    DateCellChangesetPB, MultiSelectTypeOptionPB, SelectOptionPB, SingleSelectTypeOptionPB, SELECTION_IDS_SEPARATOR,
};
use flowy_grid::services::row::RowRevisionBuilder;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};

use strum::EnumCount;

pub struct GridRowTestBuilder<'a> {
    field_revs: &'a [Arc<FieldRevision>],
    inner_builder: RowRevisionBuilder<'a>,
}

impl<'a> GridRowTestBuilder<'a> {
    pub fn new(block_id: &str, field_revs: &'a [Arc<FieldRevision>]) -> Self {
        assert_eq!(field_revs.len(), FieldType::COUNT);
        let inner_builder = RowRevisionBuilder::new(block_id, field_revs);
        Self {
            field_revs,
            inner_builder,
        }
    }

    pub fn insert_text_cell(&mut self, data: &str) -> String {
        let text_field = self.field_rev_with_type(&FieldType::RichText);
        self.inner_builder.insert_text_cell(&text_field.id, data.to_string());

        text_field.id.clone()
    }

    pub fn insert_number_cell(&mut self, data: &str) -> String {
        let number_field = self.field_rev_with_type(&FieldType::Number);
        self.inner_builder.insert_text_cell(&number_field.id, data.to_string());
        number_field.id.clone()
    }

    pub fn insert_date_cell(&mut self, data: &str) -> String {
        let value = serde_json::to_string(&DateCellChangesetPB {
            date: Some(data.to_string()),
            time: None,
        })
        .unwrap();
        let date_field = self.field_rev_with_type(&FieldType::DateTime);
        self.inner_builder.insert_text_cell(&date_field.id, value);
        date_field.id.clone()
    }

    pub fn insert_checkbox_cell(&mut self, data: &str) -> String {
        let checkbox_field = self.field_rev_with_type(&FieldType::Checkbox);
        self.inner_builder
            .insert_text_cell(&checkbox_field.id, data.to_string());

        checkbox_field.id.clone()
    }

    pub fn insert_url_cell(&mut self, data: &str) -> String {
        let url_field = self.field_rev_with_type(&FieldType::URL);
        self.inner_builder.insert_text_cell(&url_field.id, data.to_string());
        url_field.id.clone()
    }

    pub fn insert_single_select_cell<F>(&mut self, f: F) -> String
    where
        F: Fn(Vec<SelectOptionPB>) -> SelectOptionPB,
    {
        let single_select_field = self.field_rev_with_type(&FieldType::SingleSelect);
        let type_option = SingleSelectTypeOptionPB::from(&single_select_field);
        let option = f(type_option.options);
        self.inner_builder
            .insert_select_option_cell(&single_select_field.id, option.id);

        single_select_field.id.clone()
    }

    pub fn insert_multi_select_cell<F>(&mut self, f: F) -> String
    where
        F: Fn(Vec<SelectOptionPB>) -> Vec<SelectOptionPB>,
    {
        let multi_select_field = self.field_rev_with_type(&FieldType::MultiSelect);
        let type_option = MultiSelectTypeOptionPB::from(&multi_select_field);
        let options = f(type_option.options);
        let ops_ids = options
            .iter()
            .map(|option| option.id.clone())
            .collect::<Vec<_>>()
            .join(SELECTION_IDS_SEPARATOR);
        self.inner_builder
            .insert_select_option_cell(&multi_select_field.id, ops_ids);

        multi_select_field.id.clone()
    }

    pub fn field_rev_with_type(&self, field_type: &FieldType) -> FieldRevision {
        self.field_revs
            .iter()
            .find(|field_rev| {
                let t_field_type: FieldType = field_rev.field_type_rev.into();
                &t_field_type == field_type
            })
            .unwrap()
            .as_ref()
            .clone()
    }

    pub fn build(self) -> RowRevision {
        self.inner_builder.build()
    }
}

impl<'a> std::ops::Deref for GridRowTestBuilder<'a> {
    type Target = RowRevisionBuilder<'a>;

    fn deref(&self) -> &Self::Target {
        &self.inner_builder
    }
}

impl<'a> std::ops::DerefMut for GridRowTestBuilder<'a> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner_builder
    }
}
