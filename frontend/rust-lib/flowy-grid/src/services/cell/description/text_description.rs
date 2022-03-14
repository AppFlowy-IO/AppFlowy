use crate::impl_from_and_to_type_option;
use crate::services::row::StringifyCellData;
use crate::services::util::*;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Field, FieldType};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RichTextDescription {
    #[pb(index = 1)]
    pub format: String,
}
impl_from_and_to_type_option!(RichTextDescription, FieldType::RichText);

impl StringifyCellData for RichTextDescription {
    fn str_from_cell_data(&self, data: String) -> String {
        data
    }

    fn str_to_cell_data(&self, s: &str) -> Result<String, FlowyError> {
        Ok(s.to_owned())
    }
}
