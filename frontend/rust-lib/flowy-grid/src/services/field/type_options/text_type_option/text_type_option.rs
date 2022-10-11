use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{
    decode_cell_data_to_string, CellBytes, CellBytesParser, CellData, CellDataChangeset, CellDataOperation,
    CellDisplayable, FromCellString,
};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer,
};
use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct RichTextTypeOptionBuilder(RichTextTypeOptionPB);
impl_into_box_type_option_builder!(RichTextTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(RichTextTypeOptionBuilder, RichTextTypeOptionPB);

impl TypeOptionBuilder for RichTextTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::RichText
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }
    fn transform(&mut self, _field_type: &FieldType, _type_option_data: String) {
        // Do nothing
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RichTextTypeOptionPB {
    #[pb(index = 1)]
    #[serde(default)]
    data: String, //It's not used yet
}
impl_type_option!(RichTextTypeOptionPB, FieldType::RichText);

impl CellDisplayable<String> for RichTextTypeOptionPB {
    fn display_data(
        &self,
        cell_data: CellData<String>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_str: String = cell_data.try_into_inner()?;
        Ok(CellBytes::new(cell_str))
    }

    fn display_string(
        &self,
        cell_data: CellData<String>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_str: String = cell_data.try_into_inner()?;
        Ok(cell_str)
    }
}

impl CellDataOperation<String, String> for RichTextTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: CellData<String>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
            || decoded_field_type.is_url()
        {
            let s = decode_cell_data_to_string(cell_data, decoded_field_type, decoded_field_type, field_rev);
            Ok(CellBytes::new(s.unwrap_or_else(|_| "".to_owned())))
        } else {
            self.display_data(cell_data, decoded_field_type, field_rev)
        }
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let data = changeset.try_into_inner()?;
        if data.len() > 10000 {
            Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
        } else {
            Ok(data)
        }
    }
}

pub struct TextCellData(pub String);
impl AsRef<str> for TextCellData {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl std::ops::Deref for TextCellData {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl FromCellString for TextCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        Ok(TextCellData(s.to_owned()))
    }
}

impl ToString for TextCellData {
    fn to_string(&self) -> String {
        self.0.clone()
    }
}

pub struct TextCellDataParser();
impl CellBytesParser for TextCellDataParser {
    type Object = TextCellData;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => Ok(TextCellData(s)),
            Err(_) => Ok(TextCellData("".to_owned())),
        }
    }
}
