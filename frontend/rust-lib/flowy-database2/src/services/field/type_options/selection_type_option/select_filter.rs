#![allow(clippy::needless_collect)]

use crate::entities::{FieldType, SelectOptionConditionPB, SelectOptionFilterPB};
use crate::services::field::SelectOption;

impl SelectOptionFilterPB {
  pub fn is_visible(&self, selected_options: &[SelectOption], field_type: FieldType) -> bool {
    let selected_option_ids: Vec<&String> =
      selected_options.iter().map(|option| &option.id).collect();
    match self.condition {
      SelectOptionConditionPB::OptionIs => match field_type {
        FieldType::SingleSelect => {
          if self.option_ids.is_empty() {
            return true;
          }

          if selected_options.is_empty() {
            return false;
          }

          let required_options = self
            .option_ids
            .iter()
            .filter(|id| selected_option_ids.contains(id))
            .collect::<Vec<_>>();

          !required_options.is_empty()
        },
        FieldType::MultiSelect => {
          if self.option_ids.is_empty() {
            return true;
          }

          let required_options = self
            .option_ids
            .iter()
            .filter(|id| selected_option_ids.contains(id))
            .collect::<Vec<_>>();

          !required_options.is_empty()
        },
        _ => false,
      },
      SelectOptionConditionPB::OptionIsNot => match field_type {
        FieldType::SingleSelect => {
          if self.option_ids.is_empty() {
            return true;
          }

          if selected_options.is_empty() {
            return false;
          }

          let required_options = self
            .option_ids
            .iter()
            .filter(|id| selected_option_ids.contains(id))
            .collect::<Vec<_>>();

          required_options.is_empty()
        },
        FieldType::MultiSelect => {
          let required_options = self
            .option_ids
            .iter()
            .filter(|id| selected_option_ids.contains(id))
            .collect::<Vec<_>>();

          required_options.is_empty()
        },
        _ => false,
      },
      SelectOptionConditionPB::OptionIsEmpty => selected_option_ids.is_empty(),
      SelectOptionConditionPB::OptionIsNotEmpty => !selected_option_ids.is_empty(),
    }
  }
}

#[cfg(test)]
mod tests {
  #![allow(clippy::all)]
  use crate::entities::{FieldType, SelectOptionConditionPB, SelectOptionFilterPB};
  use crate::services::field::SelectOption;

  #[test]
  fn select_option_filter_is_empty_test() {
    let option = SelectOption::new("A");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIsEmpty,
      option_ids: vec![],
    };

    assert_eq!(filter.is_visible(&vec![], FieldType::SingleSelect), true);
    assert_eq!(
      filter.is_visible(&vec![option.clone()], FieldType::SingleSelect),
      false,
    );

    assert_eq!(filter.is_visible(&vec![], FieldType::MultiSelect), true);
    assert_eq!(
      filter.is_visible(&vec![option], FieldType::MultiSelect),
      false,
    );
  }

  #[test]
  fn select_option_filter_is_not_empty_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIsNotEmpty,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };

    assert_eq!(
      filter.is_visible(&vec![option_1.clone()], FieldType::SingleSelect),
      true
    );
    assert_eq!(filter.is_visible(&vec![], FieldType::SingleSelect), false,);

    assert_eq!(
      filter.is_visible(&vec![option_1.clone()], FieldType::MultiSelect),
      true
    );
    assert_eq!(filter.is_visible(&vec![], FieldType::MultiSelect), false,);
  }

  #[test]
  fn single_select_option_filter_is_not_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIsNot,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };

    for (options, is_visible) in vec![
      (vec![option_2.clone()], false),
      (vec![option_1.clone()], false),
      (vec![option_3.clone()], true),
      (vec![option_1.clone(), option_2.clone()], false),
    ] {
      assert_eq!(
        filter.is_visible(&options, FieldType::SingleSelect),
        is_visible
      );
    }
  }

  #[test]
  fn single_select_option_filter_is_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("c");

    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![option_1.id.clone()],
    };
    for (options, is_visible) in vec![
      (vec![option_1.clone()], true),
      (vec![option_2.clone()], false),
      (vec![option_3.clone()], false),
      (vec![option_1.clone(), option_2.clone()], true),
    ] {
      assert_eq!(
        filter.is_visible(&options, FieldType::SingleSelect),
        is_visible
      );
    }
  }

  #[test]
  fn single_select_option_filter_is_test2() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");

    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![],
    };
    for (options, is_visible) in vec![
      (vec![option_1.clone()], true),
      (vec![option_2.clone()], true),
      (vec![option_1.clone(), option_2.clone()], true),
    ] {
      assert_eq!(
        filter.is_visible(&options, FieldType::SingleSelect),
        is_visible
      );
    }
  }

  #[test]
  fn multi_select_option_filter_not_contains_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIsNot,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };

    for (options, is_visible) in vec![
      (vec![option_1.clone(), option_2.clone()], false),
      (vec![option_1.clone()], false),
      (vec![option_2.clone()], false),
      (vec![option_3.clone()], true),
      (
        vec![option_1.clone(), option_2.clone(), option_3.clone()],
        false,
      ),
      (vec![], true),
    ] {
      assert_eq!(
        filter.is_visible(&options, FieldType::MultiSelect),
        is_visible
      );
    }
  }
  #[test]
  fn multi_select_option_filter_contains_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");

    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };
    for (options, is_visible) in vec![
      (
        vec![option_1.clone(), option_2.clone(), option_3.clone()],
        true,
      ),
      (vec![option_2.clone(), option_1.clone()], true),
      (vec![option_2.clone()], true),
      (vec![option_1.clone(), option_3.clone()], true),
      (vec![option_3.clone()], false),
    ] {
      assert_eq!(
        filter.is_visible(&options, FieldType::MultiSelect),
        is_visible
      );
    }
  }

  #[test]
  fn multi_select_option_filter_contains_test2() {
    let option_1 = SelectOption::new("A");

    let filter = SelectOptionFilterPB {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![],
    };
    for (options, is_visible) in vec![(vec![option_1.clone()], true), (vec![], true)] {
      assert_eq!(
        filter.is_visible(&options, FieldType::MultiSelect),
        is_visible
      );
    }
  }
}
