use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{
    stringify_cell_data, try_decode_cell_data, AnyCellChangeset, CellBytes, CellBytesParser, CellComparable,
    CellDataChangeset, CellDataDecoder, CellStringParser, DecodedCellData, FromCellString, IntoCellData,
};
use crate::services::field::{BoxTypeOptionBuilder, TypeOption, TypeOptionBuilder};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

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

/// For the moment, the `RichTextTypeOptionPB` is empty. The `data` property is not
/// used yet.
#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RichTextTypeOptionPB {
    #[pb(index = 1)]
    #[serde(default)]
    data: String,
}
impl_type_option!(RichTextTypeOptionPB, FieldType::RichText);

impl TypeOption for RichTextTypeOptionPB {
    type CellData = StrCellData;
    type CellChangeset = String;
}

impl CellStringParser for RichTextTypeOptionPB {
    type Object = StrCellData;

    fn parser_cell_str(&self, s: &str) -> Option<Self::Object> {
        Some(s.into())
    }
}

impl CellDataDecoder for RichTextTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: IntoCellData<StrCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_str = cell_data.try_into_inner()?;
        Ok(CellBytes::new(cell_str))
    }

    fn try_decode_cell_data(
        &self,
        cell_data: IntoCellData<StrCellData>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
            || decoded_field_type.is_url()
        {
            let cell_data = cell_data.try_into_inner()?;
            Ok(stringify_cell_data(cell_data.into(), decoded_field_type, field_rev))
        } else {
            self.decode_cell_data(cell_data, decoded_field_type, field_rev)
        }
    }

    fn decode_cell_data_to_str(
        &self,
        cell_data: IntoCellData<StrCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_str = cell_data.try_into_inner()?.0;
        Ok(cell_str.into())
    }
}

impl CellDataChangeset for RichTextTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<String>,
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

impl CellComparable for RichTextTypeOptionPB {
    type CellData = String;

    fn apply_cmp(&self, cell_data: &Self::CellData, other_cell_data: &Self::CellData) -> Ordering {
        cell_data.cmp(other_cell_data)
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

impl DecodedCellData for TextCellData {
    type Object = TextCellData;

    fn is_empty(&self) -> bool {
        self.0.is_empty()
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

pub struct StrCellData(pub String);
impl std::ops::Deref for StrCellData {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for StrCellData {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl FromCellString for StrCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        Ok(Self(s.to_owned()))
    }
}

impl std::convert::From<String> for StrCellData {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl std::convert::From<StrCellData> for String {
    fn from(value: StrCellData) -> Self {
        value.0
    }
}
impl std::convert::From<&str> for StrCellData {
    fn from(s: &str) -> Self {
        Self(s.to_owned())
    }
}

impl AsRef<[u8]> for StrCellData {
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}
