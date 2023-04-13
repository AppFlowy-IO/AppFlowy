use crate::services::database::DatabaseEditor;
use crate::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
use collab_database::fields::TypeOptionData;

use crate::entities::FieldType;
use flowy_error::FlowyResult;
use std::sync::Arc;

pub async fn edit_field_type_option<T: From<TypeOptionData> + Into<TypeOptionData>>(
  view_id: &str,
  field_id: &str,
  editor: Arc<DatabaseEditor>,
  action: impl FnOnce(&mut T),
) -> FlowyResult<()> {
  let get_type_option = async {
    let field = editor.get_field(field_id)?;
    let field_type = FieldType::from(field.field_type);
    field.get_type_option::<T>(field_type)
  };

  if let Some(mut type_option) = get_type_option.await {
    if let Some(old_field) = editor.get_field(field_id) {
      action(&mut type_option);
      let type_option_data: TypeOptionData = type_option.into();
      editor.update_field_type_option(view_id, field_id, type_option_data, old_field);
    }
  }

  Ok(())
}

pub async fn edit_single_select_type_option(
  view_id: &str,
  field_id: &str,
  editor: Arc<DatabaseEditor>,
  action: impl FnOnce(&mut SingleSelectTypeOption),
) -> FlowyResult<()> {
  edit_field_type_option(view_id, field_id, editor, action).await
}

pub async fn edit_multi_select_type_option(
  view_id: &str,
  field_id: &str,
  editor: Arc<DatabaseEditor>,
  action: impl FnOnce(&mut MultiSelectTypeOption),
) -> FlowyResult<()> {
  edit_field_type_option(view_id, field_id, editor, action).await
}
