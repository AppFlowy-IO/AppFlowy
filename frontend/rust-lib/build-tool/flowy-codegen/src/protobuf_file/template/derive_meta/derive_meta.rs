use crate::util::get_tera;
use itertools::Itertools;
use tera::Context;

pub struct ProtobufDeriveMeta {
  context: Context,
  structs: Vec<String>,
  enums: Vec<String>,
}

#[allow(dead_code)]
impl ProtobufDeriveMeta {
  pub fn new(structs: Vec<String>, enums: Vec<String>) -> Self {
    let enums: Vec<_> = enums.into_iter().unique().collect();
    ProtobufDeriveMeta {
      context: Context::new(),
      structs,
      enums,
    }
  }

  pub fn render(&mut self) -> Option<String> {
    self.context.insert("names", &self.structs);
    self.context.insert("enums", &self.enums);

    let tera = get_tera("protobuf_file/template/derive_meta");
    match tera.render("derive_meta.tera", &self.context) {
      Ok(r) => Some(r),
      Err(e) => {
        log::error!("{:?}", e);
        None
      },
    }
  }
}
