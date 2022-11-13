use crate::entities::FieldType;
use crate::services::cell::{CellBytes, CellData};
use crate::services::field::{
    SelectOptionColorPB, SelectOptionIds, SelectOptionPB, SelectTypeOptionSharedAction, CHECK, UNCHECK,
};
use flowy_error::FlowyResult;
use grid_rev_model::FieldRevision;

/// Handles how to transform the cell data when switching between different field types
pub struct SelectOptionTypeOptionTransformer();
impl SelectOptionTypeOptionTransformer {
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
            FieldType::MultiSelect => {}
            _ => {}
        }
    }

    pub fn transform_type_option_cell_data<T>(
        shared: &T,
        cell_data: CellData<SelectOptionIds>,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>
    where
        T: SelectTypeOptionSharedAction,
    {
        match decoded_field_type {
            FieldType::SingleSelect | FieldType::MultiSelect => {
                //
                CellBytes::from(shared.get_selected_options(cell_data))
            }
            FieldType::Checkbox => {
                // transform the cell data to the option id
                let mut transformed_ids = Vec::new();
                let options = shared.options();
                cell_data.try_into_inner()?.iter().for_each(|name| {
                    if let Some(option) = options.iter().find(|option| &option.name == name) {
                        transformed_ids.push(option.id.clone());
                    }
                });
                let transformed_cell_data = CellData::from(SelectOptionIds::from(transformed_ids));
                CellBytes::from(shared.get_selected_options(transformed_cell_data))
            }
            _ => Ok(CellBytes::default()),
        }
    }
}
