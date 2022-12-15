use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{
    AnyCellChangeset, CellBytes, CellComparable, CellDataChangeset, CellDataDecoder, CellStringParser, IntoCellData,
};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{BoxTypeOptionBuilder, NumberCellData, StrCellData, TypeOption, TypeOptionBuilder};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::str::FromStr;

#[derive(Default)]
pub struct NumberTypeOptionBuilder(NumberTypeOptionPB);
impl_into_box_type_option_builder!(NumberTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(NumberTypeOptionBuilder, NumberTypeOptionPB);

impl NumberTypeOptionBuilder {
    pub fn name(mut self, name: &str) -> Self {
        self.0.name = name.to_string();
        self
    }

    pub fn set_format(mut self, format: NumberFormat) -> Self {
        self.0.set_format(format);
        self
    }

    pub fn scale(mut self, scale: u32) -> Self {
        self.0.scale = scale;
        self
    }

    pub fn positive(mut self, positive: bool) -> Self {
        self.0.sign_positive = positive;
        self
    }
}

impl TypeOptionBuilder for NumberTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::Number
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }
    fn transform(&mut self, _field_type: &FieldType, _type_option_data: String) {
        // Do nothing
    }
}

// Number
#[derive(Clone, Debug, Serialize, Deserialize, ProtoBuf)]
pub struct NumberTypeOptionPB {
    #[pb(index = 1)]
    pub format: NumberFormat,

    #[pb(index = 2)]
    pub scale: u32,

    #[pb(index = 3)]
    pub symbol: String,

    #[pb(index = 4)]
    pub sign_positive: bool,

    #[pb(index = 5)]
    pub name: String,
}
impl_type_option!(NumberTypeOptionPB, FieldType::Number);

impl TypeOption for NumberTypeOptionPB {
    type CellData = StrCellData;
    type CellChangeset = NumberCellChangeset;
}

impl NumberTypeOptionPB {
    pub fn new() -> Self {
        Self::default()
    }

    pub(crate) fn format_cell_data(&self, s: &str) -> FlowyResult<NumberCellData> {
        match self.format {
            NumberFormat::Num => match Decimal::from_str(s) {
                Ok(value, ..) => Ok(NumberCellData::from_decimal(value)),
                Err(_) => Ok(NumberCellData::new()),
            },
            _ => NumberCellData::from_format_str(s, self.sign_positive, &self.format),
        }
    }

    pub fn set_format(&mut self, format: NumberFormat) {
        self.format = format;
        self.symbol = format.symbol();
    }
}

pub(crate) fn strip_currency_symbol<T: ToString>(s: T) -> String {
    let mut s = s.to_string();
    for symbol in CURRENCY_SYMBOL.iter() {
        if s.starts_with(symbol) {
            s = s.strip_prefix(symbol).unwrap_or("").to_string();
            break;
        }
    }
    s
}

impl CellStringParser for NumberTypeOptionPB {
    type Object = NumberCellData;

    fn parser_cell_str(&self, s: &str) -> Option<Self::Object> {
        match self.format_cell_data(s) {
            Ok(num) => Some(num),
            Err(_) => None,
        }
    }
}

impl CellDataDecoder for NumberTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: IntoCellData<StrCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_data = cell_data.try_into_inner()?.0;
        match self.format_cell_data(&cell_data) {
            Ok(num) => Ok(CellBytes::new(num.to_string())),
            Err(_) => Ok(CellBytes::default()),
        }
    }

    fn try_decode_cell_data(
        &self,
        cell_data: IntoCellData<StrCellData>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if decoded_field_type.is_date() {
            return Ok(CellBytes::default());
        }

        self.decode_cell_data(cell_data, decoded_field_type, field_rev)
    }

    fn decode_cell_data_to_str(
        &self,
        cell_data: IntoCellData<StrCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_data: String = cell_data.try_into_inner()?.0;
        Ok(cell_data)
    }
}

pub type NumberCellChangeset = String;

impl CellDataChangeset for NumberTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<NumberCellChangeset>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.try_into_inner()?;
        let data = changeset.trim().to_string();
        let _ = self.format_cell_data(&data)?;
        Ok(data)
    }
}
impl CellComparable for NumberTypeOptionPB {
    type CellData = NumberCellData;

    fn apply_cmp(&self, _cell_data: &Self::CellData, _other_cell_data: &Self::CellData) -> Ordering {
        Ordering::Equal
    }
}

impl std::default::Default for NumberTypeOptionPB {
    fn default() -> Self {
        let format = NumberFormat::default();
        let symbol = format.symbol();
        NumberTypeOptionPB {
            format,
            scale: 0,
            symbol,
            sign_positive: true,
            name: "Number".to_string(),
        }
    }
}
