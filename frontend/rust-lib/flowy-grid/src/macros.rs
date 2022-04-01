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

macro_rules! impl_builder_from_json_str_and_from_bytes {
    ($target: ident,$type_option: ident) => {
        impl $target {
            pub fn from_protobuf_bytes(bytes: Bytes) -> $target {
                let type_option = $type_option::from_protobuf_bytes(bytes);
                $target(type_option)
            }

            pub fn from_json_str(s: &str) -> $target {
                let type_option = $type_option::from_json_str(s);
                $target(type_option)
            }
        }
    };
}

#[macro_export]
macro_rules! impl_type_option {
    ($target: ident, $field_type:expr) => {
        impl std::convert::From<&FieldMeta> for $target {
            fn from(field_meta: &FieldMeta) -> $target {
                match field_meta
                    .type_option_by_field_type_id
                    .get_entry::<$target>(&$field_type)
                {
                    None => $target::default(),
                    Some(target) => target,
                }
            }
        }

        impl std::convert::From<$target> for String {
            fn from(type_option: $target) -> String {
                type_option.json_str()
            }
        }

        impl TypeOptionDataEntry for $target {
            fn field_type(&self) -> FieldType {
                $field_type
            }

            fn json_str(&self) -> String {
                match serde_json::to_string(&self) {
                    Ok(s) => s,
                    Err(e) => {
                        tracing::error!("Field type data convert to AnyData fail, error: {:?}", e);
                        serde_json::to_string(&$target::default()).unwrap()
                    }
                }
            }

            fn protobuf_bytes(&self) -> Bytes {
                self.clone().try_into().unwrap()
            }
        }

        impl TypeOptionDataFrom for $target {
            fn from_json_str(s: &str) -> $target {
                match serde_json::from_str(s) {
                    Ok(obj) => obj,
                    Err(err) => {
                        tracing::error!("{} convert from any data failed, {:?}", stringify!($target), err);
                        $target::default()
                    }
                }
            }

            fn from_protobuf_bytes(bytes: Bytes) -> $target {
                $target::try_from(bytes).unwrap_or($target::default())
            }
        }
    };
}
