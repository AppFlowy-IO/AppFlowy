use crate::entities::{TextFilterConditionPB, TextFilterPB};
use crate::services::cell::{CellFilterable, TypeCellData};
use crate::services::field::{RichTextTypeOptionPB, TypeOptionCellData, TypeOptionConfiguration};
use flowy_error::FlowyResult;

impl TextFilterPB {
    pub fn is_visible<T: AsRef<str>>(&self, cell_data: T) -> bool {
        let cell_data = cell_data.as_ref().to_lowercase();
        let content = &self.content.to_lowercase();
        match self.condition {
            TextFilterConditionPB::Is => &cell_data == content,
            TextFilterConditionPB::IsNot => &cell_data != content,
            TextFilterConditionPB::Contains => cell_data.contains(content),
            TextFilterConditionPB::DoesNotContain => !cell_data.contains(content),
            TextFilterConditionPB::StartsWith => cell_data.starts_with(content),
            TextFilterConditionPB::EndsWith => cell_data.ends_with(content),
            TextFilterConditionPB::TextIsEmpty => cell_data.is_empty(),
            TextFilterConditionPB::TextIsNotEmpty => !cell_data.is_empty(),
        }
    }
}

impl CellFilterable for RichTextTypeOptionPB {
    fn apply_filter(
        &self,
        type_cell_data: TypeCellData,
        filter: &<Self as TypeOptionConfiguration>::CellFilterConfiguration,
    ) -> FlowyResult<bool> {
        if !type_cell_data.is_text() {
            return Ok(false);
        }

        let text_cell_data = self.decode_type_cell_data(type_cell_data)?;
        Ok(filter.is_visible(text_cell_data))
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{TextFilterConditionPB, TextFilterPB};

    #[test]
    fn text_filter_equal_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterConditionPB::Is,
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
            condition: TextFilterConditionPB::StartsWith,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("AppFlowy.io"), true);
        assert_eq!(text_filter.is_visible(""), false);
        assert_eq!(text_filter.is_visible("https"), false);
    }

    #[test]
    fn text_filter_end_with_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterConditionPB::EndsWith,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
        assert_eq!(text_filter.is_visible("App"), false);
        assert_eq!(text_filter.is_visible("appflowy.io"), false);
    }
    #[test]
    fn text_filter_empty_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterConditionPB::TextIsEmpty,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible(""), true);
        assert_eq!(text_filter.is_visible("App"), false);
    }
    #[test]
    fn text_filter_contain_test() {
        let text_filter = TextFilterPB {
            condition: TextFilterConditionPB::Contains,
            content: "appflowy".to_owned(),
        };

        assert_eq!(text_filter.is_visible("https://github.com/appflowy"), true);
        assert_eq!(text_filter.is_visible("AppFlowy"), true);
        assert_eq!(text_filter.is_visible("App"), false);
        assert_eq!(text_filter.is_visible(""), false);
        assert_eq!(text_filter.is_visible("github"), false);
    }
}
