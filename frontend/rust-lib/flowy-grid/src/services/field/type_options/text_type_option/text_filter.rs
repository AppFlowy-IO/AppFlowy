use crate::entities::{TextFilterCondition, TextFilterPB};
use crate::services::cell::{CellData, CellFilterOperation, TypeCellData};
use crate::services::field::{RichTextTypeOptionPB, TextCellData};
use flowy_error::FlowyResult;

impl TextFilterPB {
    pub fn is_visible<T: AsRef<str>>(&self, cell_data: T) -> bool {
        let cell_data = cell_data.as_ref().to_lowercase();
        let content = &self.content.to_lowercase();
        match self.condition {
            TextFilterCondition::Is => &cell_data == content,
            TextFilterCondition::IsNot => &cell_data != content,
            TextFilterCondition::Contains => cell_data.contains(content),
            TextFilterCondition::DoesNotContain => !cell_data.contains(content),
            TextFilterCondition::StartsWith => cell_data.starts_with(content),
            TextFilterCondition::EndsWith => cell_data.ends_with(content),
            TextFilterCondition::TextIsEmpty => cell_data.is_empty(),
            TextFilterCondition::TextIsNotEmpty => !cell_data.is_empty(),
        }
    }
}

impl CellFilterOperation<TextFilterPB> for RichTextTypeOptionPB {
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &TextFilterPB) -> FlowyResult<bool> {
        if !any_cell_data.is_text() {
            return Ok(false);
        }

        let cell_data: CellData<TextCellData> = any_cell_data.into();
        let text_cell_data = cell_data.try_into_inner()?;
        Ok(filter.is_visible(text_cell_data))
    }
}
#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{TextFilterCondition, TextFilterPB};

    #[test]
    fn text_filter_equal_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterCondition::Is,
            content: "appflowy".to_owned(),
        };

        assert!(text_filter.is_visible("AppFlowy"));
        assert_eq!(text_filter.is_visible("appflowy"), true);
        assert_eq!(text_filter.is_visible("Appflowy"), true);
        assert_eq!(text_filter.is_visible("AppFlowy.io"), false);
    }
    #[test]
    fn text_filter_start_with_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterCondition::StartsWith,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("AppFlowy.io"), true);
        assert_eq!(text_filter.is_visible(""), false);
        assert_eq!(text_filter.is_visible("https"), false);
    }

    #[test]
    fn text_filter_end_with_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterCondition::EndsWith,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
        assert_eq!(text_filter.is_visible("App"), false);
        assert_eq!(text_filter.is_visible("appflowy.io"), false);
    }
    #[test]
    fn text_filter_empty_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterCondition::TextIsEmpty,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible(""), true);
        assert_eq!(text_filter.is_visible("App"), false);
    }
    #[test]
    fn text_filter_contain_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterCondition::Contains,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
        assert_eq!(text_filter.is_visible("AppFlowy"), true);
        assert_eq!(text_filter.is_visible("App"), false);
        assert_eq!(text_filter.is_visible(""), false);
        assert_eq!(text_filter.is_visible("github"), false);
    }
}
