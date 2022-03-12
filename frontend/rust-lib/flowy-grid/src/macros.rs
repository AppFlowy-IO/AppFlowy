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
                match $target::try_from(Bytes::from(field.type_options.value.clone())) {
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

        impl std::convert::From<$target> for AnyData {
            fn from(field_description: $target) -> Self {
                let field_type = field_description.field_type();
                match field_description.try_into() {
                    Ok(bytes) => {
                        let bytes: Bytes = bytes;
                        AnyData::from_bytes(field_type, bytes)
                    }
                    Err(e) => {
                        tracing::error!("Field type data convert to AnyData fail, error: {:?}", e);
                        // it's impossible to fail when unwrapping the default field type data
                        let default_bytes: Bytes = $target::default().try_into().unwrap();
                        AnyData::from_bytes(field_type, default_bytes)
                    }
                }
            }
        }
    };
}
