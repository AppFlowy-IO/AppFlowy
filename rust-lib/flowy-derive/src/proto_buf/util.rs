pub enum TypeCategory {
    Array,
    Map,
    Str,
    Protobuf,
    Bytes,
    Enum,
    Opt,
    Primitive,
}

fn category_from_str(type_str: &str) -> TypeCategory { TypeCategory::Protobuf }

pub fn ident_category(ident: &syn::Ident) -> TypeCategory {
    let ident_str: &str = &ident.to_string();
    category_from_str(ident_str)
}
