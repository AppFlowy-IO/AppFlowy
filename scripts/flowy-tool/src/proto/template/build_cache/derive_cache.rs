use crate::util::get_tera;
use tera::{Context, Tera};

pub struct ProtobufDeriveCache {
    context: Context,
    structs: Vec<String>,
    enums: Vec<String>,
}

#[allow(dead_code)]
impl ProtobufDeriveCache {
    pub fn new(structs: Vec<String>, enums: Vec<String>) -> Self {
        return ProtobufDeriveCache {
            context: Context::new(),
            structs,
            enums,
        };
    }

    pub fn render(&mut self) -> Option<String> {
        self.context.insert("names", &self.structs);
        self.context.insert("enums", &self.enums);

        let tera = get_tera("build_cache");
        match tera.render("derive_cache.tera", &self.context) {
            Ok(r) => Some(r),
            Err(e) => {
                log::error!("{:?}", e);
                None
            }
        }
    }
}
