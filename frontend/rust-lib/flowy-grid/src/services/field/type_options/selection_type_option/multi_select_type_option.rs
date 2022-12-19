use crate::entities::{FieldType, SelectOptionFilterPB};
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellDataChangeset, FromCellString, TypeCellData};

use crate::services::field::{
    BoxTypeOptionBuilder, SelectOptionCellChangeset, SelectOptionCellDataPB, SelectOptionIds, SelectOptionPB,
    SelectTypeOptionSharedAction, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionConfiguration,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
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
}

impl TypeOptionConfiguration for MultiSelectTypeOptionPB {
    type CellFilterConfiguration = SelectOptionFilterPB;
}

impl TypeOptionCellData for MultiSelectTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        self.get_selected_options(cell_data)
    }

    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        SelectOptionIds::from_cell_str(&cell_data)
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
        changeset: AnyCellChangeset<SelectOptionCellChangeset>,
        cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content_changeset = changeset.try_into_inner()?;

        let insert_option_ids = content_changeset
            .insert_option_ids
            .into_iter()
            .filter(|insert_option_id| self.options.iter().any(|option| &option.id == insert_option_id))
            .collect::<Vec<String>>();

        let new_cell_data: String;
        match cell_rev {
            None => {
                new_cell_data = SelectOptionIds::from(insert_option_ids).to_string();
            }
            Some(cell_rev) => {
                let cell_data = TypeCellData::try_from(cell_rev)
                    .map(|data| data.into_inner())
                    .unwrap_or_default();
                let mut select_ids: SelectOptionIds = cell_data.into();
                for insert_option_id in insert_option_ids {
                    if !select_ids.contains(&insert_option_id) {
                        select_ids.push(insert_option_id);
                    }
                }

                for delete_option_id in content_changeset.delete_option_ids {
                    select_ids.retain(|id| id != &delete_option_id);
                }

                new_cell_data = select_ids.to_string();
                tracing::trace!("Multi-select cell data: {}", &new_cell_data);
            }
        }

        Ok(new_cell_data)
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
        let data = SelectOptionCellChangeset::from_insert_options(option_ids.clone()).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();

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
        let data = SelectOptionCellChangeset::from_insert_options(option_ids.clone()).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();
        assert_eq!(&*select_option_ids, &option_ids);

        // delete
        let data = SelectOptionCellChangeset::from_delete_options(option_ids).to_str();
        let select_option_ids: SelectOptionIds = type_option.apply_changeset(data.into(), None).unwrap().into();
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
        let data = SelectOptionCellChangeset::from_insert_option_id(&google.id).to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();
        assert_eq!(cell_option_ids, google.id);
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
        let data = SelectOptionCellChangeset::from_insert_option_id(&google.id).to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();
        assert!(cell_option_ids.is_empty());
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
        let data = SelectOptionCellChangeset::from_insert_option_id("").to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();
        assert_eq!(cell_option_ids, "");

        let data = SelectOptionCellChangeset::from_insert_option_id("123,456").to_str();
        let cell_option_ids = type_option.apply_changeset(data.into(), None).unwrap();
        assert_eq!(cell_option_ids, "");
    }

    #[test]
    fn multi_select_invalid_changeset_data_test() {
        let multi_select = MultiSelectTypeOptionBuilder::default();
        let field_rev = FieldBuilder::new(multi_select).name("Platform").build();
        let type_option = MultiSelectTypeOptionPB::from(&field_rev);

        // The type of the changeset should be SelectOptionCellChangeset
        assert!(type_option.apply_changeset("123".to_owned().into(), None).is_err());
    }
}
