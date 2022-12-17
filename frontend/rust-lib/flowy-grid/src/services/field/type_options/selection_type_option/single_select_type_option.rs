use crate::entities::{FieldType, SelectOptionFilterPB};
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellDataChangeset, FromCellString};
use crate::services::field::selection_type_option::type_option_transform::SelectOptionTypeOptionTransformer;
use crate::services::field::{
    BoxTypeOptionBuilder, SelectOptionCellDataPB, TypeOption, TypeOptionBuilder, TypeOptionCellData,
    TypeOptionConfiguration,
};
use crate::services::field::{
    SelectOptionCellChangeset, SelectOptionIds, SelectOptionPB, SelectTypeOptionSharedAction,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};

// Single select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SingleSelectTypeOptionPB {
    #[pb(index = 1)]
    pub options: Vec<SelectOptionPB>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(SingleSelectTypeOptionPB, FieldType::SingleSelect);

impl TypeOption for SingleSelectTypeOptionPB {
    type CellData = SelectOptionIds;
    type CellChangeset = SelectOptionCellChangeset;
    type CellPBType = SelectOptionCellDataPB;
}

impl TypeOptionConfiguration for SingleSelectTypeOptionPB {
    type CellFilterConfiguration = SelectOptionFilterPB;
}

impl TypeOptionCellData for SingleSelectTypeOptionPB {
    fn convert_into_pb_type(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellPBType {
        self.get_selected_options(cell_data)
    }

    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        SelectOptionIds::from_cell_str(&cell_data)
    }
}

impl SelectTypeOptionSharedAction for SingleSelectTypeOptionPB {
    fn number_of_max_options(&self) -> Option<usize> {
        Some(1)
    }

    fn options(&self) -> &Vec<SelectOptionPB> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB> {
        &mut self.options
    }
}

impl CellDataChangeset for SingleSelectTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<SelectOptionCellChangeset>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content_changeset = changeset.try_into_inner()?;

        let mut insert_option_ids = content_changeset
            .insert_option_ids
            .into_iter()
            .filter(|insert_option_id| self.options.iter().any(|option| &option.id == insert_option_id))
            .collect::<Vec<String>>();

        // In single select, the insert_option_ids should only contain one select option id.
        // Sometimes, the insert_option_ids may contain list of option ids. For example,
        // copy/paste a ids string.
        if insert_option_ids.is_empty() {
            Ok("".to_string())
        } else {
            // Just take the first select option
            let _ = insert_option_ids.drain(1..);
            Ok(insert_option_ids.pop().unwrap())
        }
    }
}

#[derive(Default)]
pub struct SingleSelectTypeOptionBuilder(SingleSelectTypeOptionPB);
impl_into_box_type_option_builder!(SingleSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(SingleSelectTypeOptionBuilder, SingleSelectTypeOptionPB);

impl SingleSelectTypeOptionBuilder {
    pub fn add_option(mut self, opt: SelectOptionPB) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for SingleSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::SingleSelect
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }

    fn transform(&mut self, field_type: &FieldType, type_option_data: String) {
        SelectOptionTypeOptionTransformer::transform_type_option(&mut self.0, field_type, type_option_data)
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataChangeset;
    use crate::services::field::type_options::*;
    use crate::services::field::{FieldBuilder, TypeOptionBuilder};

    #[test]
    fn single_select_transform_with_checkbox_type_option_test() {
        let checkbox_type_option_builder = CheckboxTypeOptionBuilder::default();
        let checkbox_type_option_data = checkbox_type_option_builder.serializer().json_str();

        let mut single_select = SingleSelectTypeOptionBuilder::default();
        single_select.transform(&FieldType::Checkbox, checkbox_type_option_data.clone());
        debug_assert_eq!(single_select.0.options.len(), 2);

        // Already contain the yes/no option. It doesn't need to insert new options
        single_select.transform(&FieldType::Checkbox, checkbox_type_option_data);
        debug_assert_eq!(single_select.0.options.len(), 2);
    }

    #[test]
    fn single_select_transform_with_multi_select_type_option_test() {
        let mut multiselect_type_option_builder = MultiSelectTypeOptionBuilder::default();

        let google = SelectOptionPB::new("Google");
        multiselect_type_option_builder = multiselect_type_option_builder.add_option(google);

        let facebook = SelectOptionPB::new("Facebook");
        multiselect_type_option_builder = multiselect_type_option_builder.add_option(facebook);

        let multiselect_type_option_data = multiselect_type_option_builder.serializer().json_str();

        let mut single_select = SingleSelectTypeOptionBuilder::default();
        single_select.transform(&FieldType::MultiSelect, multiselect_type_option_data.clone());
        debug_assert_eq!(single_select.0.options.len(), 2);

        // Already contain the yes/no option. It doesn't need to insert new options
        single_select.transform(&FieldType::MultiSelect, multiselect_type_option_data);
        debug_assert_eq!(single_select.0.options.len(), 2);
    }

    #[test]
    fn single_select_insert_multi_option_test() {
        let google = SelectOptionPB::new("Google");
        let facebook = SelectOptionPB::new("Facebook");
        let single_select = SingleSelectTypeOptionBuilder::default()
            .add_option(google.clone())
            .add_option(facebook.clone());

        let field_rev = FieldBuilder::new(single_select).name("Platform").build();
        let type_option = SingleSelectTypeOptionPB::from(&field_rev);
        let option_ids = vec![google.id.clone(), facebook.id];
        let data = SelectOptionCellChangeset::from_insert_options(option_ids).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();

        assert_eq!(&*select_option_ids, &vec![google.id]);
    }

    #[test]
    fn single_select_unselect_multi_option_test() {
        let google = SelectOptionPB::new("Google");
        let facebook = SelectOptionPB::new("Facebook");
        let single_select = SingleSelectTypeOptionBuilder::default()
            .add_option(google.clone())
            .add_option(facebook.clone());

        let field_rev = FieldBuilder::new(single_select).name("Platform").build();
        let type_option = SingleSelectTypeOptionPB::from(&field_rev);
        let option_ids = vec![google.id.clone(), facebook.id];

        // insert
        let data = SelectOptionCellChangeset::from_insert_options(option_ids.clone()).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();
        assert_eq!(&*select_option_ids, &vec![google.id]);

        // delete
        let data = SelectOptionCellChangeset::from_delete_options(option_ids).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();
        assert!(select_option_ids.is_empty());
    }

    #[test]
    fn single_select_insert_non_exist_option_test() {
        let google = SelectOptionPB::new("Google");
        let single_select = SingleSelectTypeOptionBuilder::default();
        let field_rev = FieldBuilder::new(single_select).name("Platform").build();
        let type_option = SingleSelectTypeOptionPB::from(&field_rev);

        let option_ids = vec![google.id];
        let data = SelectOptionCellChangeset::from_insert_options(option_ids).to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();

        assert!(cell_option_ids.is_empty());
    }

    #[test]
    fn single_select_insert_invalid_option_id_test() {
        let single_select = SingleSelectTypeOptionBuilder::default();
        let field_rev = FieldBuilder::new(single_select).name("Platform").build();
        let type_option = SingleSelectTypeOptionPB::from(&field_rev);

        let data = SelectOptionCellChangeset::from_insert_option_id("").to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();
        assert_eq!(cell_option_ids, "");
    }

    #[test]
    fn single_select_invalid_changeset_data_test() {
        let single_select = SingleSelectTypeOptionBuilder::default();
        let field_rev = FieldBuilder::new(single_select).name("Platform").build();
        let type_option = SingleSelectTypeOptionPB::from(&field_rev);

        // The type of the changeset should be SelectOptionCellChangeset
        assert!(type_option.apply_changeset("123".to_owned().into(), None).is_err());
    }
}
