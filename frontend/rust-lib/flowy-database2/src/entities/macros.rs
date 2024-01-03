#[macro_export]
macro_rules! impl_into_field_type {
  ($target: ident) => {
    impl std::convert::From<$target> for FieldType {
      fn from(ty: $target) -> Self {
        match ty {
          0 => FieldType::RichText,
          1 => FieldType::Number,
          2 => FieldType::DateTime,
          3 => FieldType::SingleSelect,
          4 => FieldType::MultiSelect,
          5 => FieldType::Checkbox,
          6 => FieldType::URL,
          7 => FieldType::Checklist,
          8 => FieldType::LastEditedTime,
          9 => FieldType::CreatedTime,
          10 => FieldType::Relation,
          _ => {
            tracing::error!("🔴Can't parse FieldType from value: {}", ty);
            FieldType::RichText
          },
        }
      }
    }
  };
}

#[macro_export]
macro_rules! impl_into_field_visibility {
  ($target: ident) => {
    impl std::convert::From<$target> for FieldVisibility {
      fn from(ty: $target) -> Self {
        match ty {
          0 => FieldVisibility::AlwaysShown,
          1 => FieldVisibility::HideWhenEmpty,
          2 => FieldVisibility::AlwaysHidden,
          _ => {
            tracing::error!("🔴Can't parse FieldVisibility from value: {}", ty);
            FieldVisibility::AlwaysShown
          },
        }
      }
    }
  };
}
