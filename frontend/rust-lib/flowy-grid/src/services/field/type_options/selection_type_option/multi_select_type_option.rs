use crate::entities::{FieldType, SelectOptionFilterPB};
use crate::impl_type_option;
use crate::services::cell::{CellDataChangeset, FromCellString, TypeCellData};

use crate::services::field::{
    BoxTypeOptionBuilder, SelectOptionCellChangeset, SelectOptionCellDataPB, SelectOptionIds, SelectOptionPB,
    SelectTypeOptionSharedAction, SelectedSelectOptions, TypeOption, TypeOptionBuilder, TypeOptionCellData,
    TypeOptionCellDataFilter,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};

// Multiple select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct MultiSelectTypeOptionPB {
    #[pb(index = 1)]
    pub options: Vec<SelectOptionPB>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(MultiSelectTypeOptionPB, FieldType::MultiSelect);

impl TypeOption for MultiSelectTypeOptionPB {
    type CellData = SelectOptionIds;
    type CellChangeset = SelectOptionCellChangeset;
    type CellProtobufType = SelectOptionCellDataPB;
    type CellFilter = SelectOptionFilterPB;
}

impl TypeOptionCellData for MultiSelectTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        self.get_selected_options(cell_data)
    }

    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        SelectOptionIds::from_cell_str(&cell_str)
    }
}

impl SelectTypeOptionSharedAction for MultiSelectTypeOptionPB {
    fn number_of_max_options(&self) -> Option<usize> {
        None
    }

    fn options(&self) -> &Vec<SelectOptionPB> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB> {
        &mut self.options
    }
}

impl CellDataChangeset for MultiSelectTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        let insert_option_ids = changeset
            .insert_option_ids
            .into_iter()
            .filter(|insert_option_id| self.options.iter().any(|option| &option.id == insert_option_id))
            .collect::<Vec<String>>();

        match type_cell_data {
            None => Ok(SelectOptionIds::from(insert_option_ids)),
            Some(type_cell_data) => {
                let mut select_ids: SelectOptionIds = type_cell_data.cell_str.into();
                for insert_option_id in insert_option_ids {
                    if !select_ids.contains(&insert_option_id) {
                        select_ids.push(insert_option_id);
                    }
                }

                for delete_option_id in changeset.delete_option_ids {
                    select_ids.retain(|id| id != &delete_option_id);
                }

                tracing::trace!("Multi-select cell data: {}", select_ids.to_string());
                Ok(select_ids)
            }
        }
    }
}

impl TypeOptionCellDataFilter for MultiSelectTypeOptionPB {
    fn apply_filter2(
        &self,
        filter: &<Self as TypeOption>::CellFilter,
        field_type: &FieldType,
        cell_data: &<Self as TypeOption>::CellData,
    ) -> bool {
        if !field_type.is_multi_select() {
            return true;
        }
        let selected_options = SelectedSelectOptions::from(self.get_selected_options(cell_data.clone()));
        filter.is_visible(&selected_options, FieldType::MultiSelect)
    }
}

#[derive(Default)]
pub struct MultiSelectTypeOptionBuilder(MultiSelectTypeOptionPB);
impl_into_box_type_option_builder!(MultiSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(MultiSelectTypeOptionBuilder, MultiSelectTypeOptionPB);
impl MultiSelectTypeOptionBuilder {
    pub fn add_option(mut self, opt: SelectOptionPB) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for MultiSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::MultiSelect
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataChangeset;
    use crate::services::field::type_options::selection_type_option::*;
    use crate::services::field::{CheckboxTypeOptionBuilder, FieldBuilder, TypeOptionBuilder, TypeOptionTransform};
    use crate::services::field::{MultiSelectTypeOptionBuilder, MultiSelectTypeOptionPB};

    #[test]
    fn multi_select_transform_with_checkbox_type_option_test() {
        let checkbox_type_option_builder = CheckboxTypeOptionBuilder::default();
        let checkbox_type_option_data = checkbox_type_option_builder.serializer().json_str();

        let mut multi_select = MultiSelectTypeOptionBuilder::default().0;
        multi_select.transform_type_option(FieldType::Checkbox, checkbox_type_option_data.clone());
        debug_assert_eq!(multi_select.options.len(), 2);

        // Already contain the yes/no option. It doesn't need to insert new options
        multi_select.transform_type_option(FieldType::Checkbox, checkbox_type_option_data);
        debug_assert_eq!(multi_select.options.len(), 2);
    }

    #[test]
    fn multi_select_transform_with_single_select_type_option_test() {
        let mut singleselect_type_option_builder = SingleSelectTypeOptionBuilder::default();

        let google = SelectOptionPB::new("Google");
        singleselect_type_option_builder = singleselect_type_option_builder.add_option(google);

        let facebook = SelectOptionPB::new("Facebook");
        singleselect_type_option_builder = singleselect_type_option_builder.add_option(facebook);

        let singleselect_type_option_data = singleselect_type_option_builder.serializer().json_str();

        let mut multi_select = MultiSelectTypeOptionBuilder::default().0;
        multi_select.transform_type_option(FieldType::MultiSelect, singleselect_type_option_data.clone());
        debug_assert_eq!(multi_select.options.len(), 2);

        // Already contain the yes/no option. It doesn't need to insert new options
        multi_select.transform_type_option(FieldType::MultiSelect, singleselect_type_option_data);
        debug_assert_eq!(multi_select.options.len(), 2);
    }

    // #[test]

    #[test]
    fn multi_select_insert_multi_option_test() {
        let google = SelectOptionPB::new("Google");
        let facebook = SelectOptionPB::new("Facebook");
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .add_option(google.clone())
            .add_option(facebook.clone());

        let field_rev = FieldBuilder::new(multi_select).name("Platform").build();
        let type_option = MultiSelectTypeOptionPB::from(&field_rev);
        let option_ids = vec![google.id, facebook.id];
        let changeset = SelectOptionCellChangeset::from_insert_options(option_ids.clone());
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(changeset, None).unwrap();

        assert_eq!(&*select_option_ids, &option_ids);
    }

    #[test]
    fn multi_select_unselect_multi_option_test() {
        let google = SelectOptionPB::new("Google");
        let facebook = SelectOptionPB::new("Facebook");
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .add_option(google.clone())
            .add_option(facebook.clone());

        let field_rev = FieldBuilder::new(multi_select).name("Platform").build();
        let type_option = MultiSelectTypeOptionPB::from(&field_rev);
        let option_ids = vec![google.id, facebook.id];

        // insert
        let changeset = SelectOptionCellChangeset::from_insert_options(option_ids.clone());
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert_eq!(&*select_option_ids, &option_ids);

        // delete
        let changeset = SelectOptionCellChangeset::from_delete_options(option_ids);
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert!(select_option_ids.is_empty());
    }

    #[test]
    fn multi_select_insert_single_option_test() {
        let google = SelectOptionPB::new("Google");
        let multi_select = MultiSelectTypeOptionBuilder::default().add_option(google.clone());

        let field_rev = FieldBuilder::new(multi_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = MultiSelectTypeOptionPB::from(&field_rev);
        let changeset = SelectOptionCellChangeset::from_insert_option_id(&google.id);
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert_eq!(select_option_ids.to_string(), google.id);
    }

    #[test]
    fn multi_select_insert_non_exist_option_test() {
        let google = SelectOptionPB::new("Google");
        let multi_select = MultiSelectTypeOptionBuilder::default();
        let field_rev = FieldBuilder::new(multi_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = MultiSelectTypeOptionPB::from(&field_rev);
        let changeset = SelectOptionCellChangeset::from_insert_option_id(&google.id);
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert!(select_option_ids.is_empty());
    }

    #[test]
    fn multi_select_insert_invalid_option_id_test() {
        let google = SelectOptionPB::new("Google");
        let multi_select = MultiSelectTypeOptionBuilder::default().add_option(google);

        let field_rev = FieldBuilder::new(multi_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = MultiSelectTypeOptionPB::from(&field_rev);

        // empty option id string
        let changeset = SelectOptionCellChangeset::from_insert_option_id("");
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert_eq!(select_option_ids.to_string(), "");

        let changeset = SelectOptionCellChangeset::from_insert_option_id("123,456");
        let select_option_ids = type_option.apply_changeset(changeset, None).unwrap();
        assert!(select_option_ids.is_empty());
    }
}
