use crate::entities::{FieldType, TextFilterPB};
use crate::impl_type_option;
use crate::services::cell::{
    stringify_cell_data, CellDataChangeset, CellDataDecoder, CellProtobufBlobParser, DecodedCellData, FromCellString,
    TypeCellData,
};
use crate::services::field::{
    BoxTypeOptionBuilder, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionCellDataCompare,
    TypeOptionCellDataFilter, TypeOptionTransform,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use protobuf::ProtobufError;
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
    type CellProtobufType = StrCellData;
    type CellFilter = TextFilterPB;
}

impl TypeOptionTransform for RichTextTypeOptionPB {
    fn transformable(&self) -> bool {
        true
    }

    fn transform_type_option(&mut self, _old_type_option_field_type: FieldType, _old_type_option_data: String) {}

    fn transform_type_option_cell_str(
        &self,
        cell_str: &str,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> Option<<Self as TypeOption>::CellData> {
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
            || decoded_field_type.is_url()
        {
            Some(stringify_cell_data(cell_str.to_owned(), decoded_field_type, decoded_field_type, field_rev).into())
        } else {
            StrCellData::from_cell_str(&cell_str).ok()
        }
    }
}

impl TypeOptionCellData for RichTextTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        cell_data
    }

    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        StrCellData::from_cell_str(&cell_str)
    }
}

impl CellDataDecoder for RichTextTypeOptionPB {
    fn decode_cell_str(
        &self,
        cell_str: String,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        StrCellData::from_cell_str(&cell_str)
    }

    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
        cell_data.to_string()
    }
}

impl CellDataChangeset for RichTextTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        _type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if changeset.len() > 10000 {
            Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
        } else {
            Ok(StrCellData(changeset))
        }
    }
}

impl TypeOptionCellDataFilter for RichTextTypeOptionPB {
    fn apply_filter(
        &self,
        filter: &<Self as TypeOption>::CellFilter,
        field_type: &FieldType,
        cell_data: &<Self as TypeOption>::CellData,
    ) -> bool {
        if !field_type.is_text() {
            return false;
        }

        filter.is_visible(cell_data)
    }
}

impl TypeOptionCellDataCompare for RichTextTypeOptionPB {
    fn apply_cmp(
        &self,
        cell_data: &<Self as TypeOption>::CellData,
        other_cell_data: &<Self as TypeOption>::CellData,
    ) -> Ordering {
        cell_data.0.cmp(&other_cell_data.0)
    }
}

#[derive(Clone)]
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
impl CellProtobufBlobParser for TextCellDataParser {
    type Object = TextCellData;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => Ok(TextCellData(s)),
            Err(_) => Ok(TextCellData("".to_owned())),
        }
    }
}

#[derive(Default, Debug, Clone)]
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

impl ToString for StrCellData {
    fn to_string(&self) -> String {
        self.0.clone()
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

impl std::convert::TryFrom<StrCellData> for Bytes {
    type Error = ProtobufError;

    fn try_from(value: StrCellData) -> Result<Self, Self::Error> {
        Ok(Bytes::from(value.0))
    }
}

impl AsRef<[u8]> for StrCellData {
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}
impl AsRef<str> for StrCellData {
    fn as_ref(&self) -> &str {
        self.0.as_str()
    }
}
