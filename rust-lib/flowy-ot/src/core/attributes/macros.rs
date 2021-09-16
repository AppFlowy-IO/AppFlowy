#[macro_export]
macro_rules! inline_attribute {
    (
        $key: ident,
        $value: ty
    ) => {
        pub fn $key(value: $value) -> Self {
            Self {
                key: AttributeKey::$key,
                value: value.into(),
                scope: AttributeScope::Inline,
            }
        }
    };
}

#[macro_export]
macro_rules! block_attribute {
    (
        $key: ident,
        $value: ty
    ) => {
        pub fn $key(value: $value) -> Self {
            Self {
                key: AttributeKey::$key,
                value: value.into(),
                scope: AttributeScope::Block,
            }
        }
    };
}

#[macro_export]
macro_rules! list_attribute {
    (
        $key: ident,
        $value: expr
    ) => {
        pub fn $key(b: bool) -> Self {
            let value = match b {
                true => $value,
                false => "",
            };
            Attribute::List(value)
        }
    };
}

#[macro_export]
macro_rules! ignore_attribute {
    (
        $key: ident,
        $value: ident
    ) => {
        pub fn $key(value: $value) -> Self {
            Self {
                key: AttributeKey::$key,
                value: value.into(),
                scope: AttributeScope::Ignore,
            }
        }
    };
}
