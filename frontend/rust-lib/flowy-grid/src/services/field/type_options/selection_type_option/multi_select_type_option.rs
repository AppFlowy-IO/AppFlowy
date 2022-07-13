use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{CellBytes, CellData, CellDataChangeset, CellDataOperation, CellDisplayable};
use crate::services::field::type_options::util::get_cell_data;
use crate::services::field::{
    make_selected_select_options, BoxTypeOptionBuilder, SelectOption, SelectOptionCellChangeset, SelectOptionCellData,
    SelectOptionIds, SelectOptionOperation, TypeOptionBuilder, SELECTION_IDS_SEPARATOR,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use serde::{Deserialize, Serialize};

// Multiple select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct MultiSelectTypeOption {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(MultiSelectTypeOption, FieldType::MultiSelect);

impl SelectOptionOperation for MultiSelectTypeOption {
    fn selected_select_option(&self, cell_data: CellData<SelectOptionIds>) -> SelectOptionCellData {
        let select_options = make_selected_select_options(cell_data, &self.options);
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

impl CellDataOperation<SelectOptionIds, SelectOptionCellChangeset> for MultiSelectTypeOption {
    fn decode_cell_data(
        &self,
        cell_data: CellData<SelectOptionIds>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if !decoded_field_type.is_select_option() {
            return Ok(CellBytes::default());
        }

        self.display_data(cell_data, decoded_field_type, field_rev)
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<SelectOptionCellChangeset>,
        cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content_changeset = changeset.try_into_inner()?;
        let new_cell_data: String;
        match cell_rev {
            None => {
                new_cell_data = content_changeset.insert_option_id.unwrap_or_else(|| "".to_owned());
            }
            Some(cell_rev) => {
                let cell_data = get_cell_data(&cell_rev);
                let mut select_ids: SelectOptionIds = cell_data.into();
                if let Some(insert_option_id) = content_changeset.insert_option_id {
                    tracing::trace!("Insert multi select option: {}", &insert_option_id);
                    if select_ids.contains(&insert_option_id) {
                        select_ids.retain(|id| id != &insert_option_id);
                    } else {
                        select_ids.push(insert_option_id);
                    }
                }

                if let Some(delete_option_id) = content_changeset.delete_option_id {
                    tracing::trace!("Delete multi select option: {}", &delete_option_id);
                    select_ids.retain(|id| id != &delete_option_id);
                }

                new_cell_data = select_ids.join(SELECTION_IDS_SEPARATOR);
                tracing::trace!("Multi select cell data: {}", &new_cell_data);
            }
        }

        Ok(new_cell_data)
    }
}

#[derive(Default)]
pub struct MultiSelectTypeOptionBuilder(MultiSelectTypeOption);
impl_into_box_type_option_builder!(MultiSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(MultiSelectTypeOptionBuilder, MultiSelectTypeOption);
impl MultiSelectTypeOptionBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for MultiSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::MultiSelect
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}
#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataOperation;
    use crate::services::field::type_options::selection_type_option::*;
    use crate::services::field::FieldBuilder;
    use crate::services::field::{MultiSelectTypeOption, MultiSelectTypeOptionBuilder};
    use flowy_grid_data_model::revision::FieldRevision;

    #[test]
    fn multi_select_test() {
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let twitter_option = SelectOption::new("Twitter");
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone())
            .option(twitter_option);

        let field_rev = FieldBuilder::new(multi_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = MultiSelectTypeOption::from(&field_rev);

        let option_ids = vec![google_option.id.clone(), facebook_option.id.clone()].join(SELECTION_IDS_SEPARATOR);
        let data = SelectOptionCellChangeset::from_insert(&option_ids).to_str();
        let cell_data = type_option.apply_changeset(data.into(), None).unwrap();
        assert_multi_select_options(
            cell_data,
            &type_option,
            &field_rev,
            vec![google_option.clone(), facebook_option],
        );

        let data = SelectOptionCellChangeset::from_insert(&google_option.id).to_str();
        let cell_data = type_option.apply_changeset(data.into(), None).unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_rev, vec![google_option]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellChangeset::from_insert("").to_str().into(), None)
            .unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_rev, vec![]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellChangeset::from_insert("123,456").to_str().into(), None)
            .unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_rev, vec![]);

        // Invalid changeset
        assert!(type_option.apply_changeset("123".to_owned().into(), None).is_err());
    }

    fn assert_multi_select_options(
        cell_data: String,
        type_option: &MultiSelectTypeOption,
        field_rev: &FieldRevision,
        expected: Vec<SelectOption>,
    ) {
        let field_type: FieldType = field_rev.field_type_rev.into();
        assert_eq!(
            expected,
            type_option
                .decode_cell_data(cell_data.into(), &field_type, field_rev)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
        );
    }
}
