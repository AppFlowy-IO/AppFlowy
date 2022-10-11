use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{CellBytes, CellData, CellDataChangeset, CellDataOperation, CellDisplayable};
use crate::services::field::type_options::util::get_cell_data;
use crate::services::field::{
    make_selected_select_options, BoxTypeOptionBuilder, SelectOptionCellChangeset, SelectOptionCellDataPB,
    SelectOptionIds, SelectOptionOperation, SelectOptionPB, TypeOptionBuilder,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataFormat};
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

impl SelectOptionOperation for MultiSelectTypeOptionPB {
    fn selected_select_option(&self, cell_data: CellData<SelectOptionIds>) -> SelectOptionCellDataPB {
        let select_options = make_selected_select_options(cell_data, &self.options);
        SelectOptionCellDataPB {
            options: self.options.clone(),
            select_options,
        }
    }

    fn options(&self) -> &Vec<SelectOptionPB> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB> {
        &mut self.options
    }
}

impl CellDataOperation<SelectOptionIds, SelectOptionCellChangeset> for MultiSelectTypeOptionPB {
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
                let cell_data = get_cell_data(&cell_rev);
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
                tracing::trace!("Multi select cell data: {}", &new_cell_data);
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

    fn data_format(&self) -> &dyn TypeOptionDataFormat {
        &self.0
    }
}
#[cfg(test)]
mod tests {
    use crate::services::cell::CellDataOperation;
    use crate::services::field::type_options::selection_type_option::*;
    use crate::services::field::FieldBuilder;
    use crate::services::field::{MultiSelectTypeOptionBuilder, MultiSelectTypeOptionPB};

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
