use crate::entities::{FieldType, NumberFilterPB};
use crate::impl_type_option;
use crate::services::cell::{CellComparable, CellDataChangeset, CellDataDecoder, TypeCellData};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{
    BoxTypeOptionBuilder, NumberCellData, StrCellData, TypeOption, TypeOptionBuilder, TypeOptionCellData,
    TypeOptionCellDataFilter, TypeOptionConfiguration, TypeOptionTransform,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::default::Default;
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
    type CellProtobufType = StrCellData;
    type CellFilter = NumberFilterPB;
}

impl TypeOptionConfiguration for NumberTypeOptionPB {
    type CellFilterConfiguration = NumberFilterPB;
}

impl TypeOptionCellData for NumberTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        cell_data
    }

    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        Ok(cell_str.into())
    }
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

impl TypeOptionTransform for NumberTypeOptionPB {}

impl CellDataDecoder for NumberTypeOptionPB {
    fn decode_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if decoded_field_type.is_date() {
            return Ok(Default::default());
        }

        let str_cell_data = self.decode_type_option_cell_str(cell_str)?;
        let s = self.format_cell_data(&str_cell_data)?.to_string();
        Ok(s.into())
    }

    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
        match self.format_cell_data(&cell_data) {
            Ok(cell_data) => cell_data.to_string(),
            Err(_) => "".to_string(),
        }
    }
}

pub type NumberCellChangeset = String;

impl CellDataChangeset for NumberTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        _type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        let data = changeset.trim().to_string();
        let _ = self.format_cell_data(&data)?;
        Ok(StrCellData(data))
    }
}

impl TypeOptionCellDataFilter for NumberTypeOptionPB {
    fn apply_filter2(
        &self,
        filter: &<Self as TypeOption>::CellFilter,
        field_type: &FieldType,
        cell_data: &<Self as TypeOption>::CellData,
    ) -> bool {
        if !field_type.is_number() {
            return true;
        }
        match self.format_cell_data(cell_data) {
            Ok(cell_data) => filter.is_visible(&cell_data),
            Err(_) => true,
        }
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
