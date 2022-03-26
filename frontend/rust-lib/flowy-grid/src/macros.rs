#[macro_export]
macro_rules! impl_into_box_type_option_builder {
    ($target: ident) => {
        impl std::convert::From<$target> for BoxTypeOptionBuilder {
            fn from(target: $target) -> BoxTypeOptionBuilder {
                Box::new(target)
            }
        }
    };
}

macro_rules! impl_from_json_str_and_from_bytes {
    ($target: ident,$type_option: ident) => {
        impl $target {
            pub fn from_json_str(s: &str) -> $target {
                $target($type_option::from(s))
            }

            pub fn from_bytes(bytes: Bytes) -> $target {
                let type_option = $type_option::try_from(bytes).unwrap_or($type_option::default());
                $target(type_option)
            }
        }
    };
}

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
        impl std::convert::From<&FieldMeta> for $target {
            fn from(field_meta: &FieldMeta) -> $target {
                $target::from(field_meta.type_option_json.as_str())
            }
        }

        impl std::convert::From<&str> for $target {
            fn from(type_option_str: &str) -> $target {
                match serde_json::from_str(type_option_str) {
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
