use flowy_grid::entities::FieldType;
use flowy_grid::services::field::selection_type_option::{SelectOption, SELECTION_IDS_SEPARATOR};
use flowy_grid::services::field::{DateCellChangeset, MultiSelectTypeOption, SingleSelectTypeOption};
use flowy_grid::services::row::RowRevisionBuilder;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use std::sync::Arc;
use strum::EnumCount;

pub struct GridRowTestBuilder<'a> {
    block_id: String,
    field_revs: &'a [Arc<FieldRevision>],
    inner_builder: RowRevisionBuilder<'a>,
}

impl<'a> GridRowTestBuilder<'a> {
    pub fn new(block_id: &str, field_revs: &'a [Arc<FieldRevision>]) -> Self {
        assert_eq!(field_revs.len(), FieldType::COUNT);
        let inner_builder = RowRevisionBuilder::new(field_revs);
        Self {
            block_id: block_id.to_owned(),
            field_revs,
            inner_builder,
        }
    }

    pub fn insert_text_cell(&mut self, data: &str) -> String {
        let text_field = self.field_rev_with_type(&FieldType::RichText);
        self.inner_builder
            .insert_cell(&text_field.id, data.to_string())
            .unwrap();

        text_field.id.clone()
    }

    pub fn insert_number_cell(&mut self, data: &str) -> String {
        let number_field = self.field_rev_with_type(&FieldType::Number);
        self.inner_builder
            .insert_cell(&number_field.id, data.to_string())
            .unwrap();
        number_field.id.clone()
    }

    pub fn insert_date_cell(&mut self, data: &str) -> String {
        let value = serde_json::to_string(&DateCellChangeset {
            date: Some(data.to_string()),
            time: None,
        })
        .unwrap();
        let date_field = self.field_rev_with_type(&FieldType::DateTime);
        self.inner_builder.insert_cell(&date_field.id, value).unwrap();
        date_field.id.clone()
    }

    pub fn insert_checkbox_cell(&mut self, data: &str) {
        let number_field = self.field_rev_with_type(&FieldType::Checkbox);
        self.inner_builder
            .insert_cell(&number_field.id, data.to_string())
            .unwrap();
    }

    pub fn insert_url_cell(&mut self, data: &str) -> String {
        let url_field = self.field_rev_with_type(&FieldType::URL);
        self.inner_builder.insert_cell(&url_field.id, data.to_string()).unwrap();
        url_field.id.clone()
    }

    pub fn insert_single_select_cell<F>(&mut self, f: F) -> String
    where
        F: Fn(&Vec<SelectOption>) -> &SelectOption,
    {
        let single_select_field = self.field_rev_with_type(&FieldType::SingleSelect);
        let type_option = SingleSelectTypeOption::from(&single_select_field);
        let option = f(&type_option.options);
        self.inner_builder
            .insert_select_option_cell(&single_select_field.id, option.id.clone())
            .unwrap();

        single_select_field.id.clone()
    }

    pub fn insert_multi_select_cell<F>(&mut self, f: F)
    where
        F: Fn(&Vec<SelectOption>) -> &Vec<SelectOption>,
    {
        let multi_select_field = self.field_rev_with_type(&FieldType::MultiSelect);
        let type_option = MultiSelectTypeOption::from(&multi_select_field);
        let options = f(&type_option.options);
        let ops_ids = options
            .iter()
            .map(|option| option.id.clone())
            .collect::<Vec<_>>()
            .join(SELECTION_IDS_SEPARATOR);
        self.inner_builder
            .insert_select_option_cell(&multi_select_field.id, ops_ids)
            .unwrap();
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
        self.inner_builder.build(&self.block_id)
    }
}
