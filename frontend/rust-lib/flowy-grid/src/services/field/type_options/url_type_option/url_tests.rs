#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::{CellDataChangeset, CellDataDecoder, IntoCellData};

    use crate::services::field::{FieldBuilder, URLCellDataParser};
    use crate::services::field::{URLCellData, URLTypeOptionPB};
    use grid_rev_model::FieldRevision;

    /// The expected_str will equal to the input string, but the expected_url will be empty if there's no
    /// http url in the input string.
    #[test]
    fn url_type_option_does_not_contain_url_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(&type_option, "123", "123", "", &field_type, &field_rev);
        assert_url(&type_option, "", "", "", &field_type, &field_rev);
    }

    /// The expected_str will equal to the input string, but the expected_url will not be empty
    /// if there's a http url in the input string.
    #[test]
    fn url_type_option_contains_url_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(
            &type_option,
            "AppFlowy website - https://www.appflowy.io",
            "AppFlowy website - https://www.appflowy.io",
            "https://www.appflowy.io/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "AppFlowy website appflowy.io",
            "AppFlowy website appflowy.io",
            "https://appflowy.io",
            &field_type,
            &field_rev,
        );
    }

    /// if there's a http url and some words following it in the input string.
    #[test]
    fn url_type_option_contains_url_with_string_after_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(
            &type_option,
            "AppFlowy website - https://www.appflowy.io welcome!",
            "AppFlowy website - https://www.appflowy.io welcome!",
            "https://www.appflowy.io/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "AppFlowy website appflowy.io welcome!",
            "AppFlowy website appflowy.io welcome!",
            "https://appflowy.io",
            &field_type,
            &field_rev,
        );
    }

    /// if there's a http url and special words following it in the input string.
    #[test]
    fn url_type_option_contains_url_with_special_string_after_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(
            &type_option,
            "AppFlowy website - https://www.appflowy.io!",
            "AppFlowy website - https://www.appflowy.io!",
            "https://www.appflowy.io/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "AppFlowy website appflowy.io!",
            "AppFlowy website appflowy.io!",
            "https://appflowy.io",
            &field_type,
            &field_rev,
        );
    }

    /// if there's a level4 url in the input string.
    #[test]
    fn level4_url_type_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(
            &type_option,
            "test - https://tester.testgroup.appflowy.io",
            "test - https://tester.testgroup.appflowy.io",
            "https://tester.testgroup.appflowy.io/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "test tester.testgroup.appflowy.io",
            "test tester.testgroup.appflowy.io",
            "https://tester.testgroup.appflowy.io",
            &field_type,
            &field_rev,
        );
    }

    /// urls with different top level domains.
    #[test]
    fn different_top_level_domains_test() {
        let type_option = URLTypeOptionPB::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(
            &type_option,
            "appflowy - https://appflowy.com",
            "appflowy - https://appflowy.com",
            "https://appflowy.com/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "appflowy - https://appflowy.top",
            "appflowy - https://appflowy.top",
            "https://appflowy.top/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "appflowy - https://appflowy.net",
            "appflowy - https://appflowy.net",
            "https://appflowy.net/",
            &field_type,
            &field_rev,
        );

        assert_url(
            &type_option,
            "appflowy - https://appflowy.edu",
            "appflowy - https://appflowy.edu",
            "https://appflowy.edu/",
            &field_type,
            &field_rev,
        );
    }

    fn assert_url(
        type_option: &URLTypeOptionPB,
        input_str: &str,
        expected_str: &str,
        expected_url: &str,
        field_type: &FieldType,
        field_rev: &FieldRevision,
    ) {
        let encoded_data = type_option.apply_changeset(input_str.to_owned().into(), None).unwrap();
        let decode_cell_data = decode_cell_data(encoded_data, type_option, field_rev, field_type);
        assert_eq!(expected_str.to_owned(), decode_cell_data.content);
        assert_eq!(expected_url.to_owned(), decode_cell_data.url);
    }

    fn decode_cell_data<T: Into<IntoCellData<URLCellData>>>(
        encoded_data: T,
        type_option: &URLTypeOptionPB,
        field_rev: &FieldRevision,
        field_type: &FieldType,
    ) -> URLCellData {
        type_option
            .try_decode_cell_data(encoded_data.into(), field_type, field_rev)
            .unwrap()
            .parser::<URLCellDataParser>()
            .unwrap()
    }
}
