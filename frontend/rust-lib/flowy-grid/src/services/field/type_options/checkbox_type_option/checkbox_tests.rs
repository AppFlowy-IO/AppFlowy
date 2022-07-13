#[cfg(test)]
mod tests {
    use crate::services::cell::{apply_cell_data_changeset, decode_any_cell_data};
    use crate::services::field::type_options::checkbox_type_option::{NO, YES};
    use crate::services::field::FieldBuilder;

    use crate::entities::FieldType;

    #[test]
    fn checkout_box_description_test() {
        let field_rev = FieldBuilder::from_field_type(&FieldType::Checkbox).build();
        let data = apply_cell_data_changeset("true", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev).to_string(), YES);

        let data = apply_cell_data_changeset("1", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev,).to_string(), YES);

        let data = apply_cell_data_changeset("yes", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev,).to_string(), YES);

        let data = apply_cell_data_changeset("false", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev,).to_string(), NO);

        let data = apply_cell_data_changeset("no", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev,).to_string(), NO);

        let data = apply_cell_data_changeset("12", None, &field_rev).unwrap();
        assert_eq!(decode_any_cell_data(data, &field_rev,).to_string(), NO);
    }
}
