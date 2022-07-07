use crate::services::field::NumberCellData;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::revision::GridFilterRevision;
use rust_decimal::prelude::Zero;
use rust_decimal::Decimal;
use std::str::FromStr;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridNumberFilter {
    #[pb(index = 1)]
    pub condition: NumberFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

impl GridNumberFilter {
    pub fn apply(&self, num_cell_data: &NumberCellData) -> bool {
        if self.content.is_none() {
            return false;
        }

        let content = self.content.as_ref().unwrap();
        let zero_decimal = Decimal::zero();
        let cell_decimal = num_cell_data.decimal().as_ref().unwrap_or(&zero_decimal);
        match Decimal::from_str(content) {
            Ok(decimal) => match self.condition {
                NumberFilterCondition::Equal => cell_decimal == &decimal,
                NumberFilterCondition::NotEqual => cell_decimal != &decimal,
                NumberFilterCondition::GreaterThan => cell_decimal > &decimal,
                NumberFilterCondition::LessThan => cell_decimal < &decimal,
                NumberFilterCondition::GreaterThanOrEqualTo => cell_decimal >= &decimal,
                NumberFilterCondition::LessThanOrEqualTo => cell_decimal <= &decimal,
                NumberFilterCondition::NumberIsEmpty => num_cell_data.is_empty(),
                NumberFilterCondition::NumberIsNotEmpty => !num_cell_data.is_empty(),
            },
            Err(_) => false,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum NumberFilterCondition {
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    LessThan = 3,
    GreaterThanOrEqualTo = 4,
    LessThanOrEqualTo = 5,
    NumberIsEmpty = 6,
    NumberIsNotEmpty = 7,
}

impl std::default::Default for NumberFilterCondition {
    fn default() -> Self {
        NumberFilterCondition::Equal
    }
}

impl std::convert::From<NumberFilterCondition> for i32 {
    fn from(value: NumberFilterCondition) -> Self {
        value as i32
    }
}
impl std::convert::TryFrom<u8> for NumberFilterCondition {
    type Error = ErrorCode;

    fn try_from(n: u8) -> Result<Self, Self::Error> {
        match n {
            0 => Ok(NumberFilterCondition::Equal),
            1 => Ok(NumberFilterCondition::NotEqual),
            2 => Ok(NumberFilterCondition::GreaterThan),
            3 => Ok(NumberFilterCondition::LessThan),
            4 => Ok(NumberFilterCondition::GreaterThanOrEqualTo),
            5 => Ok(NumberFilterCondition::LessThanOrEqualTo),
            6 => Ok(NumberFilterCondition::NumberIsEmpty),
            7 => Ok(NumberFilterCondition::NumberIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<GridFilterRevision>> for GridNumberFilter {
    fn from(rev: Arc<GridFilterRevision>) -> Self {
        GridNumberFilter {
            condition: NumberFilterCondition::try_from(rev.condition).unwrap_or(NumberFilterCondition::Equal),
            content: rev.content.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::{GridNumberFilter, NumberFilterCondition};

    use crate::services::field::{NumberCellData, NumberFormat};
    use std::str::FromStr;
    #[test]
    fn number_filter_equal_test() {
        let number_filter = GridNumberFilter {
            condition: NumberFilterCondition::Equal,
            content: Some("123".to_owned()),
        };

        for (num_str, r) in [("123", true), ("1234", false), ("", false)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.apply(&data), r);
        }

        let format = NumberFormat::USD;
        for (num_str, r) in [("$123", true), ("1234", false), ("", false)] {
            let data = NumberCellData::from_format_str(num_str, true, &format).unwrap();
            assert_eq!(number_filter.apply(&data), r);
        }
    }
    #[test]
    fn number_filter_greater_than_test() {
        let number_filter = GridNumberFilter {
            condition: NumberFilterCondition::GreaterThan,
            content: Some("12".to_owned()),
        };
        for (num_str, r) in [("123", true), ("10", false), ("30", true), ("", false)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.apply(&data), r);
        }
    }

    #[test]
    fn number_filter_less_than_test() {
        let number_filter = GridNumberFilter {
            condition: NumberFilterCondition::LessThan,
            content: Some("100".to_owned()),
        };
        for (num_str, r) in [("12", true), ("1234", false), ("30", true), ("", true)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.apply(&data), r);
        }
    }
}
