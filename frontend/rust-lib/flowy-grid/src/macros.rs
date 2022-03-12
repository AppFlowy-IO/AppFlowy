#[macro_export]
macro_rules! impl_from_and_to_type_option {
    ($target: ident, $field_type:expr) => {
        impl_from_field_type_option!($target);
        impl_to_field_type_option!($target, $field_type);
    };
}

#[macro_export]
macro_rules! impl_from_field_type_option {
    ($target: ident) => {
        impl std::convert::From<&Field> for $target {
            fn from(field: &Field) -> $target {
                match serde_json::from_str(&field.type_options) {
                    Ok(obj) => obj,
                    Err(err) => {
                        tracing::error!("{} convert from any data failed, {:?}", stringify!($target), err);
                        $target::default()
                    }
                }
            }
        }
    };
}

#[macro_export]
macro_rules! impl_to_field_type_option {
    ($target: ident, $field_type:expr) => {
        impl $target {
            pub fn field_type(&self) -> FieldType {
                $field_type
            }
        }

        impl std::convert::From<$target> for String {
            fn from(field_description: $target) -> Self {
                match serde_json::to_string(&field_description) {
                    Ok(s) => s,
                    Err(e) => {
                        tracing::error!("Field type data convert to AnyData fail, error: {:?}", e);
                        serde_json::to_string(&$target::default()).unwrap()
                    }
                }
            }
        }
    };
}
