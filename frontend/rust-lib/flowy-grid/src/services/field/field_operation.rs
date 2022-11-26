use crate::services::field::{MultiSelectTypeOptionPB, SingleSelectTypeOptionPB};
use crate::services::grid_editor::GridRevisionEditor;
use flowy_error::FlowyResult;
use grid_rev_model::{TypeOptionDataDeserializer, TypeOptionDataSerializer};
use std::sync::Arc;

pub async fn edit_field_type_option<T>(
    field_id: &str,
    editor: Arc<GridRevisionEditor>,
    action: impl FnOnce(&mut T),
) -> FlowyResult<()>
where
    T: TypeOptionDataDeserializer + TypeOptionDataSerializer,
{
    let get_type_option = async {
        let field_rev = editor.get_field_rev(field_id).await?;
        field_rev.get_type_option::<T>(field_rev.ty)
    };

    if let Some(mut type_option) = get_type_option.await {
        let old_field_rev = editor.get_field_rev(field_id).await;

        action(&mut type_option);
        let bytes = type_option.protobuf_bytes().to_vec();
        let _ = editor
            .did_update_field_type_option(&editor.grid_id, field_id, bytes, old_field_rev)
            .await?;
    }

    Ok(())
}

pub async fn edit_single_select_type_option(
    field_id: &str,
    editor: Arc<GridRevisionEditor>,
    action: impl FnOnce(&mut SingleSelectTypeOptionPB),
) -> FlowyResult<()> {
    edit_field_type_option(field_id, editor, action).await
}

pub async fn edit_multi_select_type_option(
    field_id: &str,
    editor: Arc<GridRevisionEditor>,
    action: impl FnOnce(&mut MultiSelectTypeOptionPB),
) -> FlowyResult<()> {
    edit_field_type_option(field_id, editor, action).await
}
