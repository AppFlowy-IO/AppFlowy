use crate::util::get_tera;
use flowy_ast::*;
use phf::phf_map;
use tera::{Context, Tera};

// Protobuf data type : https://developers.google.com/protocol-buffers/docs/proto3
static RUST_TYPE_MAP: phf::Map<&'static str, &'static str> = phf_map! {
    "String" => "string",
    "i64" => "int64",
    "i32" => "int32",
    "u64" => "uint64",
    "u32" => "uint32",
    "Vec" => "repeated",
    "f64" => "double",
    "HashMap" => "map",
};

pub struct StructTemplate {
    context: Context,
    fields: Vec<String>,
}

#[allow(dead_code)]
impl StructTemplate {
    pub fn new() -> Self {
        return StructTemplate {
            context: Context::new(),
            fields: vec![],
        };
    }

    pub fn set_message_struct_name(&mut self, name: &str) {
        self.context.insert("struct_name", name);
    }

    pub fn set_field(&mut self, field: &ASTField) {
        // {{ field_type }} {{ field_name }} = {{index}};
        let name = field.name().unwrap().to_string();
        let index = field.attrs.pb_index().unwrap();

        let ty: &str = &field.ty_as_str();
        let mut mapped_ty: &str = ty;

        if RUST_TYPE_MAP.contains_key(ty) {
            mapped_ty = RUST_TYPE_MAP[ty];
        }

        match field.bracket_category {
            Some(ref category) => match category {
                BracketCategory::Opt => self.fields.push(format!(
                    "oneof one_of_{} {{ {} {} = {}; }};",
                    name, mapped_ty, name, index
                )),
                BracketCategory::Map((k, v)) => {
                    let key: &str = k;
                    let value: &str = v;
                    self.fields.push(format!(
                        // map<string, string> attrs = 1;
                        "map<{}, {}> {} = {};",
                        RUST_TYPE_MAP.get(key).unwrap_or(&key),
                        RUST_TYPE_MAP.get(value).unwrap_or(&value),
                        name,
                        index
                    ));
                }
                BracketCategory::Vec => {
                    let bracket_ty: &str = &field.bracket_ty.as_ref().unwrap().to_string();
                    if mapped_ty == "u8" && bracket_ty == "Vec" {
                        self.fields.push(format!("bytes {} = {};", name, index))
                    } else {
                        self.fields.push(format!(
                            "{} {} {} = {};",
                            RUST_TYPE_MAP[bracket_ty], mapped_ty, name, index
                        ))
                    }
                }
                BracketCategory::Other => self
                    .fields
                    .push(format!("{} {} = {};", mapped_ty, name, index)),
            },
            None => {}
        }
    }

    pub fn render(&mut self) -> Option<String> {
        self.context.insert("fields", &self.fields);
        let tera = get_tera("proto_file");
        match tera.render("struct.tera", &self.context) {
            Ok(r) => Some(r),
            Err(e) => {
                log::error!("{:?}", e);
                None
            }
        }
    }
}
