#[macro_export]
macro_rules! impl_any_data {
    ($target: ident, $field_type:expr) => {
        impl_field_type_data_from_field!($target);
        impl_field_type_data_from_field_type_option!($target);
        impl_type_option_from_field_data!($target, $field_type);
    };
}

#[macro_export]
macro_rules! impl_field_type_data_from_field {
    ($target: ident) => {
        impl std::convert::From<&Field> for $target {
            fn from(field: &Field) -> $target {
                $target::from(&field.type_options)
            }
        }
    };
}

#[macro_export]
macro_rules! impl_field_type_data_from_field_type_option {
    ($target: ident) => {
        impl std::convert::From<&AnyData> for $target {
            fn from(any_data: &AnyData) -> $target {
                match $target::try_from(Bytes::from(any_data.value.clone())) {
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
macro_rules! impl_type_option_from_field_data {
    ($target: ident, $field_type:expr) => {
        impl $target {
            pub fn field_type() -> FieldType {
                $field_type
            }
        }

        impl std::convert::From<$target> for AnyData {
            fn from(field_data: $target) -> Self {
                match field_data.try_into() {
                    Ok(bytes) => {
                        let bytes: Bytes = bytes;
                        AnyData::from_bytes(&$target::field_type(), bytes)
                    }
                    Err(e) => {
                        tracing::error!("Field type data convert to AnyData fail, error: {:?}", e);
                        // it's impossible to fail when unwrapping the default field type data
                        let default_bytes: Bytes = $target::default().try_into().unwrap();
                        AnyData::from_bytes(&$target::field_type(), default_bytes)
                    }
                }
            }
        }
    };
}
