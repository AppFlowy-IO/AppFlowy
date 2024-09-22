use crate::entities::FieldType;
use crate::services::cell::CellDataDecoder;
use crate::services::field::{
  MultiSelectTypeOption, RichTextTypeOption, SelectOptionIds, SelectTypeOptionSharedAction,
  SingleSelectTypeOption, TypeOption, CHECK, UNCHECK,
};
use collab_database::database::Database;
use collab_database::fields::select_type_option::{
  SelectOption, SelectOptionColor, SelectTypeOption,
};
use collab_database::fields::TypeOptionData;
use collab_database::template::option_parse::build_options_from_cells;
use tracing::info;

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
    new_field_type: FieldType,
    database: &mut Database,
  ) where
    T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds>,
  {
    match old_field_type {
      FieldType::RichText => {
        if !shared.options().is_empty() {
          return;
        }
        let text_type_option = RichTextTypeOption::from(old_type_option_data);
        let rows = database
          .get_cells_for_field(view_id, field_id)
          .await
          .into_iter()
          .filter_map(|row| row.cell.map(|cell| (row.row_id, cell)))
          .map(|(row_id, cell)| {
            let text = text_type_option
              .decode_cell(&cell)
              .unwrap_or_default()
              .into_inner();
            (row_id, text)
          })
          .collect::<Vec<_>>();

        let options =
          build_options_from_cells(&rows.iter().map(|row| row.1.clone()).collect::<Vec<_>>());
        info!(
          "Transforming RichText to SelectOption, updating {} row's cell content",
          rows.len()
        );
        for (row_id, text_cell) in rows {
          let mut transformed_ids = Vec::new();
          if let Some(option) = options.iter().find(|option| option.name == text_cell) {
            transformed_ids.push(option.id.clone());
          }

          database
            .update_row(row_id, |row| {
              row.update_cells(|cell| {
                cell.insert(
                  field_id,
                  SelectOptionIds::from(transformed_ids).to_cell_data(new_field_type),
                );
              });
            })
            .await;
        }

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
        let options = SelectTypeOption::from(old_type_option_data).options;
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
        let options = SelectTypeOption::from(old_type_option_data).options;
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
