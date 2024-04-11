use crate::entities::FieldType;
use crate::services::field::{
  MultiSelectTypeOption, SelectOption, SelectOptionColor, SelectOptionIds,
  SelectTypeOptionSharedAction, SingleSelectTypeOption, TypeOption, CHECK, UNCHECK,
};
use collab_database::fields::TypeOptionData;

/// Handles how to transform the cell data when switching between different field types
pub(crate) struct SelectOptionTypeOptionTransformHelper();
impl SelectOptionTypeOptionTransformHelper {
  /// Transform the TypeOptionData from 'field_type' to single select option type.
  ///
  /// # Arguments
  ///
  /// * `old_field_type`: the FieldType of the passed-in TypeOptionData
  ///
  pub fn transform_type_option<T>(
    shared: &mut T,
    old_field_type: &FieldType,
    old_type_option_data: TypeOptionData,
  ) where
    T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds>,
  {
    match old_field_type {
      FieldType::Checkbox => {
        // add Yes and No options if it does not exist.
        if !shared.options().iter().any(|option| option.name == CHECK) {
          let check_option = SelectOption::with_color(CHECK, SelectOptionColor::Green);
          shared.mut_options().push(check_option);
        }

        if !shared.options().iter().any(|option| option.name == UNCHECK) {
          let uncheck_option = SelectOption::with_color(UNCHECK, SelectOptionColor::Yellow);
          shared.mut_options().push(uncheck_option);
        }
      },
      FieldType::MultiSelect => {
        let options = MultiSelectTypeOption::from(old_type_option_data).options;
        options.iter().for_each(|new_option| {
          if !shared
            .options()
            .iter()
            .any(|option| option.name == new_option.name)
          {
            shared.mut_options().push(new_option.clone());
          }
        })
      },
      FieldType::SingleSelect => {
        let options = SingleSelectTypeOption::from(old_type_option_data).options;
        options.iter().for_each(|new_option| {
          if !shared
            .options()
            .iter()
            .any(|option| option.name == new_option.name)
          {
            shared.mut_options().push(new_option.clone());
          }
        })
      },
      _ => {},
    }
  }
}
