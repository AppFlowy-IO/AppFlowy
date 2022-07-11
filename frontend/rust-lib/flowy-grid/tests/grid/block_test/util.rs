use crate::grid::block_test::script::GridRowTest;

use flowy_grid::entities::FieldType;
use flowy_grid::services::field::DateCellChangeset;
use flowy_grid::services::row::{CreateRowRevisionBuilder, CreateRowRevisionPayload};
use flowy_grid_data_model::revision::FieldRevision;
use strum::EnumCount;

pub struct GridRowTestBuilder<'a> {
    test: &'a GridRowTest,
    inner_builder: CreateRowRevisionBuilder<'a>,
}

impl<'a> GridRowTestBuilder<'a> {
    pub fn new(test: &'a GridRowTest) -> Self {
        assert_eq!(test.field_revs().len(), FieldType::COUNT);

        let inner_builder = CreateRowRevisionBuilder::new(test.field_revs());
        Self { test, inner_builder }
    }
    #[allow(dead_code)]
    pub fn update_text_cell(mut self, data: String) -> Self {
        let text_field = self.field_rev_with_type(&FieldType::DateTime);
        self.inner_builder.add_cell(&text_field.id, data).unwrap();
        self
    }

    #[allow(dead_code)]
    pub fn update_number_cell(mut self, data: String) -> Self {
        let number_field = self.field_rev_with_type(&FieldType::DateTime);
        self.inner_builder.add_cell(&number_field.id, data).unwrap();
        self
    }

    #[allow(dead_code)]
    pub fn update_date_cell(mut self, value: i64) -> Self {
        let value = serde_json::to_string(&DateCellChangeset {
            date: Some(value.to_string()),
            time: None,
        })
        .unwrap();
        let date_field = self.field_rev_with_type(&FieldType::DateTime);
        self.inner_builder.add_cell(&date_field.id, value).unwrap();
        self
    }

    #[allow(dead_code)]
    pub fn update_checkbox_cell(mut self, data: bool) -> Self {
        let number_field = self.field_rev_with_type(&FieldType::Checkbox);
        self.inner_builder.add_cell(&number_field.id, data.to_string()).unwrap();
        self
    }

    #[allow(dead_code)]
    pub fn update_url_cell(mut self, data: String) -> Self {
        let number_field = self.field_rev_with_type(&FieldType::Checkbox);
        self.inner_builder.add_cell(&number_field.id, data).unwrap();
        self
    }

    pub fn field_rev_with_type(&self, field_type: &FieldType) -> FieldRevision {
        self.test
            .field_revs()
            .iter()
            .find(|field_rev| {
                let t_field_type: FieldType = field_rev.field_type_rev.into();
                &t_field_type == field_type
            })
            .unwrap()
            .as_ref()
            .clone()
    }

    pub fn build(self) -> CreateRowRevisionPayload {
        self.inner_builder.build()
    }
}
