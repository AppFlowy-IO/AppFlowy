#[macro_export]
macro_rules! inline_attribute_entry {
    (
        $key: ident,
        $value: ty
    ) => {
        pub fn $key(value: $value) -> crate::core::AttributeEntry {
            AttributeEntry {
                key: BuildInTextAttributeKey::$key.as_ref().to_string(),
                value: value.into(),
            }
        }
    };
}

#[macro_export]
macro_rules! inline_list_attribute_entry {
    (
        $key: ident,
        $value: expr
    ) => {
        pub fn $key(b: bool) -> crate::core::AttributeEntry {
            let value = match b {
                true => $value,
                false => "",
            };

            AttributeEntry {
                key: BuildInTextAttributeKey::List.as_ref().to_string(),
                value: value.into(),
            }
        }
    };
}
