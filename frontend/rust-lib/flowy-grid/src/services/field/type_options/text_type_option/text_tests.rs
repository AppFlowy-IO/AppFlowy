#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataDecoder;
    use crate::services::field::FieldBuilder;

    use crate::services::field::*;

    // Test parser the cell data which field's type is FieldType::Date to cell data
    // which field's type is FieldType::Text
    #[test]
    fn date_type_to_text_type() {
        let type_option = RichTextTypeOptionPB::default();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        assert_eq!(
            type_option
                .decode_cell_str(1647251762.to_string(), &field_type, &field_rev)
                .unwrap()
                .as_str(),
            "Mar 14,2022"
        );
    }

    // Test parser the cell data which field's type is FieldType::SingleSelect to cell data
    // which field's type is FieldType::Text
    #[test]
    fn single_select_to_text_type() {
        let type_option = RichTextTypeOptionPB::default();

        let field_type = FieldType::SingleSelect;
        let done_option = SelectOptionPB::new("Done");
        let option_id = done_option.id.clone();
        let single_select = SingleSelectTypeOptionBuilder::default().add_option(done_option.clone());
        let field_rev = FieldBuilder::new(single_select).build();

        assert_eq!(
            type_option
                .decode_cell_str(option_id, &field_type, &field_rev)
                .unwrap()
                .to_string(),
            done_option.name,
        );
    }
    /*
    - [Unit Test] Testing the switching from Multi-selection type to Text type
    - Tracking : https://github.com/AppFlowy-IO/AppFlowy/issues/1183
     */
    #[test]
    fn multiselect_to_text_type() {
        let text_type_option = RichTextTypeOptionPB::default();
        let field_type = FieldType::MultiSelect;

        let France = SelectOptionPB::new("France");
        let france_optionId = France.id.clone();

        let Argentina = SelectOptionPB::new("Argentina");
        let argentina_optionId = Argentina.id.clone();

        let multi_select = MultiSelectTypeOptionBuilder::default()
            .add_option(France.clone())
            .add_option(Argentina.clone());

        let field_rev = FieldBuilder::new(multi_select).build();

        assert_eq!(
            text_type_option
                .decode_cell_str(
                    format!("{},{}", france_optionId, argentina_optionId),
                    &field_type,
                    &field_rev
                )
                .unwrap()
                .to_string(),
            format!("{},{}", France.name, Argentina.name)
        );
    }
}
