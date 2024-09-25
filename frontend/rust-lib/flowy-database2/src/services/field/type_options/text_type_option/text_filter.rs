use collab_database::{fields::Field, rows::Cell};

use crate::entities::{TextFilterConditionPB, TextFilterPB};
use crate::services::cell::insert_text_cell;
use crate::services::filter::PreFillCellsWithFilter;

impl TextFilterPB {
  pub fn is_visible<T: AsRef<str>>(&self, cell_data: T) -> bool {
    let cell_data = cell_data.as_ref().to_lowercase();
    let content = &self.content.to_lowercase();

    match self.condition {
      TextFilterConditionPB::TextIs
      | TextFilterConditionPB::TextIsNot
      | TextFilterConditionPB::TextContains
      | TextFilterConditionPB::TextDoesNotContain
      | TextFilterConditionPB::TextStartsWith
      | TextFilterConditionPB::TextEndsWith
        if content.is_empty() =>
      {
        true
      },
      TextFilterConditionPB::TextIs => &cell_data == content,
      TextFilterConditionPB::TextIsNot => &cell_data != content,
      TextFilterConditionPB::TextContains => cell_data.contains(content),
      TextFilterConditionPB::TextDoesNotContain => !cell_data.contains(content),
      TextFilterConditionPB::TextStartsWith => cell_data.starts_with(content),
      TextFilterConditionPB::TextEndsWith => cell_data.ends_with(content),
      TextFilterConditionPB::TextIsEmpty => cell_data.is_empty(),
      TextFilterConditionPB::TextIsNotEmpty => !cell_data.is_empty(),
    }
  }
}

impl PreFillCellsWithFilter for TextFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> (Option<Cell>, bool) {
    let text = match self.condition {
      TextFilterConditionPB::TextIs
      | TextFilterConditionPB::TextContains
      | TextFilterConditionPB::TextStartsWith
      | TextFilterConditionPB::TextEndsWith
        if !self.content.is_empty() =>
      {
        Some(self.content.clone())
      },
      _ => None,
    };

    let open_after_create = matches!(self.condition, TextFilterConditionPB::TextIsNotEmpty);

    (text.map(|s| insert_text_cell(s, field)), open_after_create)
  }
}

#[cfg(test)]
mod tests {
  #![allow(clippy::all)]
  use crate::entities::{TextFilterConditionPB, TextFilterPB};

  #[test]
  fn text_filter_equal_test() {
    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextIs,
      content: "appflowy".to_owned(),
    };

    assert_eq!(text_filter.is_visible("AppFlowy"), true);
    assert_eq!(text_filter.is_visible("appflowy"), true);
    assert_eq!(text_filter.is_visible("Appflowy"), true);
    assert_eq!(text_filter.is_visible("AppFlowy.io"), false);
    assert_eq!(text_filter.is_visible(""), false);

    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextIs,
      content: "".to_owned(),
    };

    assert_eq!(text_filter.is_visible("AppFlowy"), true);
    assert_eq!(text_filter.is_visible("appflowy"), true);
    assert_eq!(text_filter.is_visible("Appflowy"), true);
    assert_eq!(text_filter.is_visible("AppFlowy.io"), true);
    assert_eq!(text_filter.is_visible(""), true);
  }
  #[test]
  fn text_filter_start_with_test() {
    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextStartsWith,
      content: "appflowy".to_owned(),
    };

    assert_eq!(text_filter.is_visible("AppFlowy.io"), true);
    assert_eq!(text_filter.is_visible(""), false);
    assert_eq!(text_filter.is_visible("https"), false);
    assert_eq!(text_filter.is_visible(""), false);

    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextStartsWith,
      content: "".to_owned(),
    };

    assert_eq!(text_filter.is_visible("AppFlowy.io"), true);
    assert_eq!(text_filter.is_visible(""), true);
    assert_eq!(text_filter.is_visible("https"), true);
    assert_eq!(text_filter.is_visible(""), true);
  }

  #[test]
  fn text_filter_end_with_test() {
    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextEndsWith,
      content: "appflowy".to_owned(),
    };

    assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
    assert_eq!(text_filter.is_visible("App"), false);
    assert_eq!(text_filter.is_visible("appflowy.io"), false);
    assert_eq!(text_filter.is_visible(""), false);

    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextEndsWith,
      content: "".to_owned(),
    };

    assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
    assert_eq!(text_filter.is_visible("App"), true);
    assert_eq!(text_filter.is_visible("appflowy.io"), true);
    assert_eq!(text_filter.is_visible(""), true);
  }
  #[test]
  fn text_filter_empty_test() {
    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextIsEmpty,
      content: "appflowy".to_owned(),
    };

    assert_eq!(text_filter.is_visible(""), true);
    assert_eq!(text_filter.is_visible("App"), false);

    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextIsEmpty,
      content: "".to_owned(),
    };

    assert_eq!(text_filter.is_visible(""), true);
    assert_eq!(text_filter.is_visible("App"), false);
  }
  #[test]
  fn text_filter_contain_test() {
    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextContains,
      content: "appflowy".to_owned(),
    };

    assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
    assert_eq!(text_filter.is_visible("AppFlowy"), true);
    assert_eq!(text_filter.is_visible("App"), false);
    assert_eq!(text_filter.is_visible(""), false);
    assert_eq!(text_filter.is_visible("github"), false);

    let text_filter = TextFilterPB {
      condition: TextFilterConditionPB::TextContains,
      content: "".to_owned(),
    };

    assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
    assert_eq!(text_filter.is_visible("AppFlowy"), true);
    assert_eq!(text_filter.is_visible("App"), true);
    assert_eq!(text_filter.is_visible(""), true);
    assert_eq!(text_filter.is_visible("github"), true);
  }
}
