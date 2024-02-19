use crate::entities::{CheckboxCellDataPB, CheckboxFilterConditionPB, CheckboxFilterPB};

impl CheckboxFilterPB {
  pub fn is_visible(&self, cell_data: &CheckboxCellDataPB) -> bool {
    match self.condition {
      CheckboxFilterConditionPB::IsChecked => cell_data.is_checked,
      CheckboxFilterConditionPB::IsUnChecked => !cell_data.is_checked,
    }
  }
}

#[cfg(test)]
mod tests {
  use crate::entities::{CheckboxCellDataPB, CheckboxFilterConditionPB, CheckboxFilterPB};
  use std::str::FromStr;

  #[test]
  fn checkbox_filter_is_check_test() {
    let checkbox_filter = CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::IsChecked,
    };
    for (value, visible) in [
      ("true", true),
      ("yes", true),
      ("false", false),
      ("no", false),
      ("", false),
    ] {
      let data = CheckboxCellDataPB::from_str(value).unwrap();
      assert_eq!(checkbox_filter.is_visible(&data), visible);
    }
  }

  #[test]
  fn checkbox_filter_is_uncheck_test() {
    let checkbox_filter = CheckboxFilterPB {
      condition: CheckboxFilterConditionPB::IsUnChecked,
    };
    for (value, visible) in [
      ("false", true),
      ("no", true),
      ("true", false),
      ("yes", false),
      ("", true),
    ] {
      let data = CheckboxCellDataPB::from_str(value).unwrap();
      assert_eq!(checkbox_filter.is_visible(&data), visible);
    }
  }
}
