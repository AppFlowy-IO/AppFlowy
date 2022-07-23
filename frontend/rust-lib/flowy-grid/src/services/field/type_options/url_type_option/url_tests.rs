#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::{CellData, CellDataOperation};
    use crate::services::field::{FieldBuilder, URLCellDataParser};
    use crate::services::field::{URLCellDataPB, URLTypeOption};
    use flowy_grid_data_model::revision::FieldRevision;

    /// The expected_str will equal to the input string, but the expected_url will be empty if there's no
    /// http url in the input string.
    #[test]
    fn url_type_option_does_not_contain_url_test() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_url(&type_option, "123", "123", "", &field_type, &field_rev);
    }

    /// The expected_str will equal to the input string, but the expected_url will not be empty
    /// if there's a http url in the input string.
    #[test]
    fn url_type_option_contains_url_test() {
        let type_option = URLTypeOption::default();
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

    fn assert_url(
        type_option: &URLTypeOption,
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

    fn decode_cell_data<T: Into<CellData<URLCellDataPB>>>(
        encoded_data: T,
        type_option: &URLTypeOption,
        field_rev: &FieldRevision,
        field_type: &FieldType,
    ) -> URLCellDataPB {
        type_option
            .decode_cell_data(encoded_data.into(), field_type, field_rev)
            .unwrap()
            .with_parser(URLCellDataParser())
            .unwrap()
    }
}
