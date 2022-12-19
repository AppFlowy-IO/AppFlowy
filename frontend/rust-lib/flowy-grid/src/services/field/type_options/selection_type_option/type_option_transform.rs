use crate::entities::FieldType;

use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionColorPB, SelectOptionIds, SelectOptionPB, SelectTypeOptionSharedAction,
    SingleSelectTypeOptionPB, TypeOption, CHECK, UNCHECK,
};

use grid_rev_model::TypeOptionDataDeserializer;

/// Handles how to transform the cell data when switching between different field types
pub(crate) struct SelectOptionTypeOptionTransformHelper();
impl SelectOptionTypeOptionTransformHelper {
    /// Transform the TypeOptionData from 'field_type' to single select option type.
    ///
    /// # Arguments
    ///
    /// * `old_field_type`: the FieldType of the passed-in TypeOptionData
    ///
    pub fn transform_type_option<T>(shared: &mut T, old_field_type: &FieldType, old_type_option_data: String)
    where
        T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds>,
    {
        match old_field_type {
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
                let options = MultiSelectTypeOptionPB::from_json_str(&old_type_option_data).options;
                options.iter().for_each(|new_option| {
                    if !shared.options().iter().any(|option| option.name == new_option.name) {
                        shared.mut_options().push(new_option.clone());
                    }
                })
            }
            FieldType::SingleSelect => {
                let options = SingleSelectTypeOptionPB::from_json_str(&old_type_option_data).options;
                options.iter().for_each(|new_option| {
                    if !shared.options().iter().any(|option| option.name == new_option.name) {
                        shared.mut_options().push(new_option.clone());
                    }
                })
            }
            _ => {}
        }
    }

    // pub fn transform_e_option_cell_data<T>(
    //     //     shared: &T,
    //     //     cell_data: String,
    //     //     decoded_field_type: &FieldType,
    //     // ) -> <T as TypeOption>::CellData
    //     // where
    //     //     T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds> + CellDataDecoder,
    //     // {
    //     //     match decoded_field_type {
    //     //         FieldType::SingleSelect | FieldType::MultiSelect | FieldType::Checklist => {
    //     //             self.try_decode_cell_data(cell_data)
    //     //         }
    //     //         FieldType::Checkbox => {
    //     //             // transform the cell data to the option id
    //     //             let mut transformed_ids = Vec::new();
    //     //             let options = shared.options();
    //     //             cell_data.iter().for_each(|name| {
    //     //                 if let Some(option) = options.iter().find(|option| &option.name == name) {
    //     //                     transformed_ids.push(option.id.clone());
    //     //                 }
    //     //             });
    //     //             SelectOptionIds::from(transformed_ids)
    //     //         }
    //     //         _ => SelectOptionIds::from(vec![]),
    //     //     }
    //     // }typ
}
