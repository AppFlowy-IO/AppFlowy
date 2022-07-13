use crate::entities::{GridNumberFilter, NumberFilterCondition};
use crate::services::cell::{AnyCellData, CellFilterOperation};
use crate::services::field::{NumberCellData, NumberTypeOption};
use flowy_error::FlowyResult;
use rust_decimal::prelude::Zero;
use rust_decimal::Decimal;
use std::str::FromStr;

impl GridNumberFilter {
    pub fn is_visible(&self, num_cell_data: &NumberCellData) -> bool {
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

impl CellFilterOperation<GridNumberFilter> for NumberTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridNumberFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_number() {
            return Ok(true);
        }

        let cell_data = any_cell_data.data;
        let num_cell_data = self.format_cell_data(&cell_data)?;

        Ok(filter.is_visible(&num_cell_data))
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

        for (num_str, visible) in [("123", true), ("1234", false), ("", false)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.is_visible(&data), visible);
        }

        let format = NumberFormat::USD;
        for (num_str, visible) in [("$123", true), ("1234", false), ("", false)] {
            let data = NumberCellData::from_format_str(num_str, true, &format).unwrap();
            assert_eq!(number_filter.is_visible(&data), visible);
        }
    }
    #[test]
    fn number_filter_greater_than_test() {
        let number_filter = GridNumberFilter {
            condition: NumberFilterCondition::GreaterThan,
            content: Some("12".to_owned()),
        };
        for (num_str, visible) in [("123", true), ("10", false), ("30", true), ("", false)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.is_visible(&data), visible);
        }
    }

    #[test]
    fn number_filter_less_than_test() {
        let number_filter = GridNumberFilter {
            condition: NumberFilterCondition::LessThan,
            content: Some("100".to_owned()),
        };
        for (num_str, visible) in [("12", true), ("1234", false), ("30", true), ("", true)] {
            let data = NumberCellData::from_str(num_str).unwrap();
            assert_eq!(number_filter.is_visible(&data), visible);
        }
    }
}
