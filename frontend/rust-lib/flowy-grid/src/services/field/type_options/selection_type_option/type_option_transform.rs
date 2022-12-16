use crate::entities::FieldType;
use crate::services::cell::CellBytes;
use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionColorPB, SelectOptionIds, SelectOptionPB, SelectTypeOptionSharedAction,
    SingleSelectTypeOptionPB, TypeOption, CHECK, UNCHECK,
};
use flowy_error::FlowyResult;
use grid_rev_model::FieldRevision;
use serde_json;

/// Handles how to transform the cell data when switching between different field types
pub struct SelectOptionTypeOptionTransformer();
impl SelectOptionTypeOptionTransformer {
    /// Transform the TypeOptionData from 'field_type' to single select option type.
    ///
    /// # Arguments
    ///
    /// * `field_type`: the FieldType of the passed-in TypeOptionData
    /// * `type_option_data`: the data that can be parsed into corresponding TypeOptionData.
    ///
    pub fn transform_type_option<T>(shared: &mut T, field_type: &FieldType, _type_option_data: String)
    where
        T: SelectTypeOptionSharedAction,
    {
        match field_type {
            FieldType::Checkbox => {
                //add Yes and No options if it does not exist.
                if !shared.options().iter().any(|option| option.name == CHECK) {
                    let check_option = SelectOptionPB::with_color(CHECK, SelectOptionColorPB::Green);
                    shared.mut_options().push(check_option);
                }

                if !shared.options().iter().any(|option| option.name == UNCHECK) {
                    let uncheck_option = SelectOptionPB::with_color(UNCHECK, SelectOptionColorPB::Yellow);
                    shared.mut_options().push(uncheck_option);
                }
            }
            FieldType::MultiSelect => {
                let option_pb: MultiSelectTypeOptionPB = serde_json::from_str(_type_option_data.as_str()).unwrap();
                option_pb.options.iter().for_each(|new_option| {
                    if !shared.options().iter().any(|option| option.name == new_option.name) {
                        shared.mut_options().push(new_option.clone());
                    }
                })
            }
            FieldType::SingleSelect => {
                let option_pb: SingleSelectTypeOptionPB = serde_json::from_str(_type_option_data.as_str()).unwrap();
                option_pb.options.iter().for_each(|new_option| {
                    if !shared.options().iter().any(|option| option.name == new_option.name) {
                        shared.mut_options().push(new_option.clone());
                    }
                })
            }
            _ => {}
        }
    }

    pub fn transform_type_option_cell_data<T>(
        shared: &T,
        cell_data: <T as TypeOption>::CellData,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>
    where
        T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds>,
    {
        match decoded_field_type {
            FieldType::SingleSelect | FieldType::MultiSelect | FieldType::Checklist => {
                //
                CellBytes::from(shared.get_selected_options(cell_data))
            }
            FieldType::Checkbox => {
                // transform the cell data to the option id
                let mut transformed_ids = Vec::new();
                let options = shared.options();
                cell_data.iter().for_each(|name| {
                    if let Some(option) = options.iter().find(|option| &option.name == name) {
                        transformed_ids.push(option.id.clone());
                    }
                });
                CellBytes::from(shared.get_selected_options(SelectOptionIds::from(transformed_ids)))
            }
            _ => Ok(CellBytes::default()),
        }
    }
}
