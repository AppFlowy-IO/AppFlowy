use crate::entities::{FieldType, GridSelectOptionFilter};

use crate::impl_type_option;
use crate::services::field::select_option::{
    make_select_context_from, SelectOption, SelectOptionCellContentChangeset, SelectOptionCellData, SelectOptionIds,
    SelectOptionOperation,
};

use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{
    AnyCellData, CellContentChangeset, CellDataOperation, CellFilterOperation, DecodedCellData,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};

use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};

use serde::{Deserialize, Serialize};

// Single select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SingleSelectTypeOption {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(SingleSelectTypeOption, FieldType::SingleSelect);

impl SelectOptionOperation for SingleSelectTypeOption {
    fn select_option_cell_data(&self, cell_rev: &Option<CellRevision>) -> SelectOptionCellData {
        let select_options = make_select_context_from(cell_rev, &self.options);
        SelectOptionCellData {
            options: self.options.clone(),
            select_options,
        }
    }

    fn options(&self) -> &Vec<SelectOption> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOption> {
        &mut self.options
    }
}

impl CellFilterOperation<GridSelectOptionFilter> for SingleSelectTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, _filter: &GridSelectOptionFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_single_select() {
            return Ok(true);
        }
        let _ids: SelectOptionIds = any_cell_data.try_into()?;
        Ok(false)
    }
}

impl CellDataOperation<String> for SingleSelectTypeOption {
    fn decode_cell_data<T>(
        &self,
        cell_data: T,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if !decoded_field_type.is_select_option() {
            return Ok(DecodedCellData::default());
        }

        let encoded_data = cell_data.into();
        let mut cell_data = SelectOptionCellData {
            options: self.options.clone(),
            select_options: vec![],
        };

        let ids: SelectOptionIds = encoded_data.into();
        if let Some(option_id) = ids.first() {
            if let Some(option) = self.options.iter().find(|option| &option.id == option_id) {
                cell_data.select_options.push(option.clone());
            }
        }

        DecodedCellData::try_from_bytes(cell_data)
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_rev: Option<CellRevision>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let select_option_changeset: SelectOptionCellContentChangeset = serde_json::from_str(&changeset)?;
        let new_cell_data: String;
        if let Some(insert_option_id) = select_option_changeset.insert_option_id {
            tracing::trace!("Insert single select option: {}", &insert_option_id);
            new_cell_data = insert_option_id;
        } else {
            tracing::trace!("Delete single select option");
            new_cell_data = "".to_string()
        }

        Ok(new_cell_data)
    }
}

#[derive(Default)]
pub struct SingleSelectTypeOptionBuilder(SingleSelectTypeOption);
impl_into_box_type_option_builder!(SingleSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(SingleSelectTypeOptionBuilder, SingleSelectTypeOption);

impl SingleSelectTypeOptionBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for SingleSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::SingleSelect
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::field::select_option::*;
    use crate::services::field::type_options::*;
    use crate::services::field::FieldBuilder;
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::revision::FieldRevision;

    #[test]
    fn single_select_test() {
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let twitter_option = SelectOption::new("Twitter");
        let single_select = SingleSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone())
            .option(twitter_option);

        let field_rev = FieldBuilder::new(single_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = SingleSelectTypeOption::from(&field_rev);

        let option_ids = vec![google_option.id.clone(), facebook_option.id].join(SELECTION_IDS_SEPARATOR);
        let data = SelectOptionCellContentChangeset::from_insert(&option_ids).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_single_select_options(cell_data, &type_option, &field_rev, vec![google_option.clone()]);

        let data = SelectOptionCellContentChangeset::from_insert(&google_option.id).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_single_select_options(cell_data, &type_option, &field_rev, vec![google_option]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("").to_str(), None)
            .unwrap();
        assert_single_select_options(cell_data, &type_option, &field_rev, vec![]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("123").to_str(), None)
            .unwrap();

        assert_single_select_options(cell_data, &type_option, &field_rev, vec![]);

        // Invalid changeset
        assert!(type_option.apply_changeset("123", None).is_err());
    }

    fn assert_single_select_options(
        cell_data: String,
        type_option: &SingleSelectTypeOption,
        field_rev: &FieldRevision,
        expected: Vec<SelectOption>,
    ) {
        let field_type: FieldType = field_rev.field_type_rev.into();
        assert_eq!(
            expected,
            type_option
                .decode_cell_data(cell_data, &field_type, field_rev)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
        );
    }
}
