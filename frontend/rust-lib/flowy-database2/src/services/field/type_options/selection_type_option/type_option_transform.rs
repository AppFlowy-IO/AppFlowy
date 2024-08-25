use crate::entities::FieldType;
use crate::services::cell::CellDataDecoder;
use crate::services::field::{
  MultiSelectTypeOption, RichTextTypeOption, SelectOptionIds, SelectTypeOptionSharedAction,
  SingleSelectTypeOption, TypeOption, CHECK, UNCHECK,
};
use collab_database::database::Database;
use collab_database::entity::{SelectOption, SelectOptionColor};
use collab_database::fields::TypeOptionData;
use collab_database::template::option_parse::build_options_from_cells;

/// Handles how to transform the cell data when switching between different field types
pub(crate) struct SelectOptionTypeOptionTransformHelper();
impl SelectOptionTypeOptionTransformHelper {
  /// Transform the TypeOptionData from 'field_type' to single select option type.
  ///
  /// # Arguments
  ///
  /// * `old_field_type`: the FieldType of the passed-in TypeOptionData
  ///
  pub async fn transform_type_option<T>(
    shared: &mut T,
    view_id: &str,
    field_id: &str,
    old_field_type: &FieldType,
    old_type_option_data: TypeOptionData,
    database: &Database,
  ) where
    T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds>,
  {
    match old_field_type {
      FieldType::RichText => {
        if !shared.options().is_empty() {
          return;
        }
        let text_type_option = RichTextTypeOption::from(old_type_option_data);
        let cells = database
          .get_cells_for_field(view_id, field_id)
          .await
          .into_iter()
          .filter_map(|e| e.cell)
          .map(|cell| {
            text_type_option
              .decode_cell(&cell)
              .unwrap_or_default()
              .into_inner()
          })
          .collect::<Vec<_>>();
        let options = build_options_from_cells(&cells);
        shared.mut_options().extend(options);
      },
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
