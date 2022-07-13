#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::{CellData, CellDataOperation};
    use crate::services::field::FieldBuilder;
    use crate::services::field::{URLCellData, URLTypeOption};
    use flowy_grid_data_model::revision::FieldRevision;

    #[test]
    fn url_type_option_test_no_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(&type_option, "123", &field_type, &field_rev, "123", "");
    }

    #[test]
    fn url_type_option_test_contains_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(
            &type_option,
            "AppFlowy website - https://www.appflowy.io",
            &field_type,
            &field_rev,
            "AppFlowy website - https://www.appflowy.io",
            "https://www.appflowy.io/",
        );

        assert_changeset(
            &type_option,
            "AppFlowy website appflowy.io",
            &field_type,
            &field_rev,
            "AppFlowy website appflowy.io",
            "https://appflowy.io",
        );
    }

    fn assert_changeset(
        type_option: &URLTypeOption,
        cell_data: &str,
        field_type: &FieldType,
        field_rev: &FieldRevision,
        expected: &str,
        expected_url: &str,
    ) {
        let encoded_data = type_option.apply_changeset(cell_data.to_owned().into(), None).unwrap();
        let decode_cell_data = decode_cell_data(encoded_data, type_option, field_rev, field_type);
        assert_eq!(expected.to_owned(), decode_cell_data.content);
        assert_eq!(expected_url.to_owned(), decode_cell_data.url);
    }

    fn decode_cell_data<T: Into<CellData<URLCellData>>>(
        encoded_data: T,
        type_option: &URLTypeOption,
        field_rev: &FieldRevision,
        field_type: &FieldType,
    ) -> URLCellData {
        type_option
            .decode_cell_data(encoded_data.into(), field_type, field_rev)
            .unwrap()
            .parse::<URLCellData>()
            .unwrap()
    }
}
