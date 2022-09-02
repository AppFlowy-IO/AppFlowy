use crate::entities::{FieldChangesetParams, FieldType};
use crate::services::field::{select_option_operation, SelectOptionPB};
use crate::services::grid_editor::GridRevisionEditor;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataFormat};
use std::sync::Arc;

pub async fn edit_field<T>(
    field_id: &str,
    editor: Arc<GridRevisionEditor>,
    action: impl FnOnce(&mut T) -> bool,
) -> FlowyResult<()>
where
    T: TypeOptionDataDeserializer + TypeOptionDataFormat,
{
    let get_type_option = async {
        let field_rev = editor.get_field_rev(field_id).await?;
        field_rev.get_type_option::<T>(field_rev.ty)
    };

    if let Some(mut type_option) = get_type_option.await {
        if action(&mut type_option) {
            let changeset = FieldChangesetParams { ..Default::default() };
            let _ = editor.update_field(changeset).await?;
        }
    }

    Ok(())
}

pub fn insert_single_select_option(field_rev: &mut FieldRevision, options: Vec<SelectOptionPB>) -> FlowyResult<()> {
    if options.is_empty() {
        return Ok(());
    }
    let mut type_option = select_option_operation(field_rev)?;
    options.into_iter().for_each(|option| type_option.insert_option(option));
    Ok(())
}

pub fn insert_multi_select_option(field_rev: &mut FieldRevision, options: Vec<SelectOptionPB>) -> FlowyResult<()> {
    if options.is_empty() {
        return Ok(());
    }
    let mut type_option = select_option_operation(field_rev)?;
    options.into_iter().for_each(|option| type_option.insert_option(option));
    Ok(())
}
