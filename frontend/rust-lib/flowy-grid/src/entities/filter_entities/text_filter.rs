use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::revision::GridFilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridTextFilter {
    #[pb(index = 1)]
    pub condition: TextFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

impl GridTextFilter {
    pub fn apply<T: AsRef<str>>(&self, cell_data: T) -> bool {
        let cell_data = cell_data.as_ref();
        let s = cell_data.to_lowercase();
        if let Some(content) = self.content.as_ref() {
            match self.condition {
                TextFilterCondition::Is => &s == content,
                TextFilterCondition::IsNot => &s != content,
                TextFilterCondition::Contains => s.contains(content),
                TextFilterCondition::DoesNotContain => !s.contains(content),
                TextFilterCondition::StartsWith => s.starts_with(content),
                TextFilterCondition::EndsWith => s.ends_with(content),
                TextFilterCondition::TextIsEmpty => s.is_empty(),
                TextFilterCondition::TextIsNotEmpty => !s.is_empty(),
            }
        } else {
            false
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum TextFilterCondition {
    Is = 0,
    IsNot = 1,
    Contains = 2,
    DoesNotContain = 3,
    StartsWith = 4,
    EndsWith = 5,
    TextIsEmpty = 6,
    TextIsNotEmpty = 7,
}

impl std::convert::From<TextFilterCondition> for i32 {
    fn from(value: TextFilterCondition) -> Self {
        value as i32
    }
}

impl std::default::Default for TextFilterCondition {
    fn default() -> Self {
        TextFilterCondition::Is
    }
}
impl std::convert::TryFrom<u8> for TextFilterCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(TextFilterCondition::Is),
            1 => Ok(TextFilterCondition::IsNot),
            2 => Ok(TextFilterCondition::Contains),
            3 => Ok(TextFilterCondition::DoesNotContain),
            4 => Ok(TextFilterCondition::StartsWith),
            5 => Ok(TextFilterCondition::EndsWith),
            6 => Ok(TextFilterCondition::TextIsEmpty),
            7 => Ok(TextFilterCondition::TextIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<GridFilterRevision>> for GridTextFilter {
    fn from(rev: Arc<GridFilterRevision>) -> Self {
        GridTextFilter {
            condition: TextFilterCondition::try_from(rev.condition).unwrap_or(TextFilterCondition::Is),
            content: rev.content.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{GridTextFilter, TextFilterCondition};

    #[test]
    fn text_filter_equal_test() {
        let text_filter = GridTextFilter {
            condition: TextFilterCondition::Is,
            content: Some("appflowy".to_owned()),
        };

        assert!(text_filter.apply("AppFlowy"));
        assert_eq!(text_filter.apply("appflowy"), true);
        assert_eq!(text_filter.apply("Appflowy"), true);
        assert_eq!(text_filter.apply("AppFlowy.io"), false);
    }
    #[test]
    fn text_filter_start_with_test() {
        let text_filter = GridTextFilter {
            condition: TextFilterCondition::StartsWith,
            content: Some("appflowy".to_owned()),
        };

        assert_eq!(text_filter.apply("AppFlowy.io"), true);
        assert_eq!(text_filter.apply(""), false);
        assert_eq!(text_filter.apply("https"), false);
    }

    #[test]
    fn text_filter_end_with_test() {
        let text_filter = GridTextFilter {
            condition: TextFilterCondition::EndsWith,
            content: Some("appflowy".to_owned()),
        };

        assert_eq!(text_filter.apply("https://github.com/appflowy"), true);
        assert_eq!(text_filter.apply("App"), false);
        assert_eq!(text_filter.apply("appflowy.io"), false);
    }
    #[test]
    fn text_filter_empty_test() {
        let text_filter = GridTextFilter {
            condition: TextFilterCondition::TextIsEmpty,
            content: Some("appflowy".to_owned()),
        };

        assert_eq!(text_filter.apply(""), true);
        assert_eq!(text_filter.apply("App"), false);
    }
    #[test]
    fn text_filter_contain_test() {
        let text_filter = GridTextFilter {
            condition: TextFilterCondition::Contains,
            content: Some("appflowy".to_owned()),
        };

        assert_eq!(text_filter.apply("https://github.com/appflowy"), true);
        assert_eq!(text_filter.apply("AppFlowy"), true);
        assert_eq!(text_filter.apply("App"), false);
        assert_eq!(text_filter.apply(""), false);
        assert_eq!(text_filter.apply("github"), false);
    }
}
