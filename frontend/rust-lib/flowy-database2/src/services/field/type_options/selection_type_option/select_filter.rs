use collab_database::fields::select_type_option::SelectOption;
use collab_database::fields::Field;
use collab_database::rows::Cell;

use crate::entities::{SelectOptionFilterConditionPB, SelectOptionFilterPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::select_type_option_from_field;
use crate::services::filter::PreFillCellsWithFilter;

impl SelectOptionFilterPB {
  pub fn is_visible(&self, selected_options: &[SelectOption]) -> Option<bool> {
    let selected_option_ids = selected_options
      .iter()
      .map(|option| &option.id)
      .collect::<Vec<_>>();

    let get_non_empty_expected_options =
      || (!self.option_ids.is_empty()).then(|| self.option_ids.clone());

    let strategy = match self.condition {
      SelectOptionFilterConditionPB::OptionIs => {
        SelectOptionFilterStrategy::Is(get_non_empty_expected_options()?)
      },
      SelectOptionFilterConditionPB::OptionIsNot => {
        SelectOptionFilterStrategy::IsNot(get_non_empty_expected_options()?)
      },
      SelectOptionFilterConditionPB::OptionContains => {
        SelectOptionFilterStrategy::Contains(get_non_empty_expected_options()?)
      },
      SelectOptionFilterConditionPB::OptionDoesNotContain => {
        SelectOptionFilterStrategy::DoesNotContain(get_non_empty_expected_options()?)
      },
      SelectOptionFilterConditionPB::OptionIsEmpty => SelectOptionFilterStrategy::IsEmpty,
      SelectOptionFilterConditionPB::OptionIsNotEmpty => SelectOptionFilterStrategy::IsNotEmpty,
    };

    Some(strategy.filter(&selected_option_ids))
  }
}

enum SelectOptionFilterStrategy {
  Is(Vec<String>),
  IsNot(Vec<String>),
  Contains(Vec<String>),
  DoesNotContain(Vec<String>),
  IsEmpty,
  IsNotEmpty,
}

impl SelectOptionFilterStrategy {
  fn filter(self, selected_option_ids: &[&String]) -> bool {
    match self {
      SelectOptionFilterStrategy::Is(option_ids) => {
        if selected_option_ids.is_empty() {
          return false;
        }

        selected_option_ids.iter().all(|id| option_ids.contains(id))
      },
      SelectOptionFilterStrategy::IsNot(option_ids) => {
        if selected_option_ids.is_empty() {
          return true;
        }

        !selected_option_ids.iter().all(|id| option_ids.contains(id))
      },
      SelectOptionFilterStrategy::Contains(option_ids) => {
        if selected_option_ids.is_empty() {
          return false;
        }

        let required_options = option_ids
          .into_iter()
          .filter(|id| selected_option_ids.contains(&id))
          .collect::<Vec<_>>();

        !required_options.is_empty()
      },
      SelectOptionFilterStrategy::DoesNotContain(option_ids) => {
        if selected_option_ids.is_empty() {
          return true;
        }

        let required_options = option_ids
          .into_iter()
          .filter(|id| selected_option_ids.contains(&id))
          .collect::<Vec<_>>();

        required_options.is_empty()
      },
      SelectOptionFilterStrategy::IsEmpty => selected_option_ids.is_empty(),
      SelectOptionFilterStrategy::IsNotEmpty => !selected_option_ids.is_empty(),
    }
  }
}

impl PreFillCellsWithFilter for SelectOptionFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> Option<Cell> {
    let option_ids = match self.condition {
      SelectOptionFilterConditionPB::OptionIs | SelectOptionFilterConditionPB::OptionContains => {
        self
          .option_ids
          .first()
          .and_then(|id| Some(vec![id.clone()]))
      },
      SelectOptionFilterConditionPB::OptionIsNotEmpty => select_type_option_from_field(field)
        .ok()
        .map(|mut type_option| {
          let options = type_option.mut_options();
          if options.is_empty() {
            vec![]
          } else {
            vec![options.swap_remove(0).id]
          }
        }),
      _ => None,
    };

    option_ids.map(|ids| insert_select_option_cell(ids, field))
  }
}

#[cfg(test)]
mod tests {
  use crate::entities::{SelectOptionFilterConditionPB, SelectOptionFilterPB};
  use collab_database::fields::select_type_option::SelectOption;

  #[test]
  fn select_option_filter_is_empty_test() {
    let option = SelectOption::new("A");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIsEmpty,
      option_ids: vec![],
    };

    assert_eq!(filter.is_visible(&[]), Some(true));
    assert_eq!(filter.is_visible(&[option.clone()]), Some(false));
  }

  #[test]
  fn select_option_filter_is_not_empty_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIsNotEmpty,
      option_ids: vec![],
    };

    assert_eq!(filter.is_visible(&[]), Some(false));
    assert_eq!(filter.is_visible(&[option_1.clone()]), Some(true));
    assert_eq!(filter.is_visible(&[option_1, option_2]), Some(true));
  }

  #[test]
  fn select_option_filter_is_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");

    // no expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIs,
      option_ids: vec![],
    };
    for (options, is_visible) in [
      (vec![], None),
      (vec![option_1.clone()], None),
      (vec![option_1.clone(), option_2.clone()], None),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // one expected option
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIs,
      option_ids: vec![option_1.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(false)),
      (vec![option_1.clone()], Some(true)),
      (vec![option_2.clone()], Some(false)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // multiple expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIs,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(false)),
      (vec![option_1.clone()], Some(true)),
      (vec![option_2.clone()], Some(true)),
      (vec![option_3.clone()], Some(false)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }
  }

  #[test]
  fn select_option_filter_is_not_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");

    // no expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIsNot,
      option_ids: vec![],
    };
    for (options, is_visible) in [
      (vec![], None),
      (vec![option_1.clone()], None),
      (vec![option_2.clone()], None),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // one expected option
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIsNot,
      option_ids: vec![option_1.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(true)),
      (vec![option_1.clone()], Some(false)),
      (vec![option_2.clone()], Some(true)),
      (vec![option_3.clone()], Some(true)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // multiple expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionIsNot,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(true)),
      (vec![option_1.clone()], Some(false)),
      (vec![option_2.clone()], Some(false)),
      (vec![option_3.clone()], Some(true)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }
  }

  #[test]
  fn select_option_filter_contains_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");
    let option_4 = SelectOption::new("D");

    // no expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionContains,
      option_ids: vec![],
    };
    for (options, is_visible) in [
      (vec![], None),
      (vec![option_1.clone()], None),
      (vec![option_1.clone(), option_2.clone()], None),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // one expected option
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionContains,
      option_ids: vec![option_1.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(false)),
      (vec![option_1.clone()], Some(true)),
      (vec![option_2.clone()], Some(false)),
      (vec![option_1.clone(), option_2.clone()], Some(true)),
      (vec![option_3.clone(), option_4.clone()], Some(false)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // multiple expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionContains,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(false)),
      (vec![option_1.clone()], Some(true)),
      (vec![option_3.clone()], Some(false)),
      (vec![option_1.clone(), option_2.clone()], Some(true)),
      (vec![option_1.clone(), option_3.clone()], Some(true)),
      (vec![option_3.clone(), option_4.clone()], Some(false)),
      (
        vec![option_1.clone(), option_3.clone(), option_4.clone()],
        Some(true),
      ),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }
  }

  #[test]
  fn select_option_filter_does_not_contain_test() {
    let option_1 = SelectOption::new("A");
    let option_2 = SelectOption::new("B");
    let option_3 = SelectOption::new("C");
    let option_4 = SelectOption::new("D");

    // no expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionDoesNotContain,
      option_ids: vec![],
    };
    for (options, is_visible) in [
      (vec![], None),
      (vec![option_1.clone()], None),
      (vec![option_1.clone(), option_2.clone()], None),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // one expected option
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionDoesNotContain,
      option_ids: vec![option_1.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(true)),
      (vec![option_1.clone()], Some(false)),
      (vec![option_2.clone()], Some(true)),
      (vec![option_1.clone(), option_2.clone()], Some(false)),
      (vec![option_3.clone(), option_4.clone()], Some(true)),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }

    // multiple expected options
    let filter = SelectOptionFilterPB {
      condition: SelectOptionFilterConditionPB::OptionDoesNotContain,
      option_ids: vec![option_1.id.clone(), option_2.id.clone()],
    };
    for (options, is_visible) in [
      (vec![], Some(true)),
      (vec![option_1.clone()], Some(false)),
      (vec![option_3.clone()], Some(true)),
      (vec![option_1.clone(), option_2.clone()], Some(false)),
      (vec![option_1.clone(), option_3.clone()], Some(false)),
      (vec![option_3.clone(), option_4.clone()], Some(true)),
      (
        vec![option_1.clone(), option_3.clone(), option_4.clone()],
        Some(false),
      ),
    ] {
      assert_eq!(filter.is_visible(&options), is_visible);
    }
  }
}
