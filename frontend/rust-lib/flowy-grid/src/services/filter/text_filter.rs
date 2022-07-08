use crate::entities::{GridTextFilter, TextFilterCondition};

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
