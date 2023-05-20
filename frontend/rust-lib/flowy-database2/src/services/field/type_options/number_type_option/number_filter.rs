use crate::entities::{NumberFilterConditionPB, NumberFilterPB};
use crate::services::field::NumberCellFormat;
use rust_decimal::prelude::Zero;
use rust_decimal::Decimal;
use std::str::FromStr;

impl NumberFilterPB {
  pub fn is_visible(&self, num_cell_data: &NumberCellFormat) -> bool {
    if self.content.is_empty() {
      match self.condition {
        NumberFilterConditionPB::NumberIsEmpty => {
          return num_cell_data.is_empty();
        },
        NumberFilterConditionPB::NumberIsNotEmpty => {
          return !num_cell_data.is_empty();
        },
        _ => {},
      }
    }
    match num_cell_data.decimal().as_ref() {
      None => false,
      Some(cell_decimal) => {
        let decimal = Decimal::from_str(&self.content).unwrap_or_else(|_| Decimal::zero());
        match self.condition {
          NumberFilterConditionPB::Equal => cell_decimal == &decimal,
          NumberFilterConditionPB::NotEqual => cell_decimal != &decimal,
          NumberFilterConditionPB::GreaterThan => cell_decimal > &decimal,
          NumberFilterConditionPB::LessThan => cell_decimal < &decimal,
          NumberFilterConditionPB::GreaterThanOrEqualTo => cell_decimal >= &decimal,
          NumberFilterConditionPB::LessThanOrEqualTo => cell_decimal <= &decimal,
          _ => true,
        }
      },
    }
  }
}

#[cfg(test)]
mod tests {
  use crate::entities::{NumberFilterConditionPB, NumberFilterPB};
  use crate::services::field::{NumberCellFormat, NumberFormat};
  #[test]
  fn number_filter_equal_test() {
    let number_filter = NumberFilterPB {
      condition: NumberFilterConditionPB::Equal,
      content: "123".to_owned(),
    };

    for (num_str, visible) in [("123", true), ("1234", false), ("", false)] {
      let data = NumberCellFormat::from_format_str(num_str, &NumberFormat::Num).unwrap_or_default();
      assert_eq!(number_filter.is_visible(&data), visible);
    }

    let format = NumberFormat::USD;
    for (num_str, visible) in [("$123", true), ("1234", false), ("", false)] {
      let data = NumberCellFormat::from_format_str(num_str, &format).unwrap();
      assert_eq!(number_filter.is_visible(&data), visible);
    }
  }
  #[test]
  fn number_filter_greater_than_test() {
    let number_filter = NumberFilterPB {
      condition: NumberFilterConditionPB::GreaterThan,
      content: "12".to_owned(),
    };
    for (num_str, visible) in [("123", true), ("10", false), ("30", true), ("", false)] {
      let data = NumberCellFormat::from_format_str(num_str, &NumberFormat::Num).unwrap_or_default();
      assert_eq!(number_filter.is_visible(&data), visible);
    }
  }

  #[test]
  fn number_filter_less_than_test() {
    let number_filter = NumberFilterPB {
      condition: NumberFilterConditionPB::LessThan,
      content: "100".to_owned(),
    };
    for (num_str, visible) in [("12", true), ("1234", false), ("30", true), ("", false)] {
      let data = NumberCellFormat::from_format_str(num_str, &NumberFormat::Num).unwrap_or_default();
      assert_eq!(number_filter.is_visible(&data), visible);
    }
  }
}
