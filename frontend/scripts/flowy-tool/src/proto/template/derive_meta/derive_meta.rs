#![allow(clippy::all)]
#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::proto::proto_info::{CrateProtoInfo, ProtoFile};
use crate::util::{get_tera, read_file};
use itertools::Itertools;
use std::fs::OpenOptions;
use std::io::Write;
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

        let tera = get_tera("proto/template/derive_meta");
        match tera.render("derive_meta.tera", &self.context) {
            Ok(r) => Some(r),
            Err(e) => {
                log::error!("{:?}", e);
                None
            }
        }
    }
}

pub fn write_derive_meta(crate_infos: &[CrateProtoInfo], derive_meta_dir: &str) {
    let file_proto_infos = crate_infos
        .iter()
        .map(|ref crate_info| &crate_info.files)
        .flatten()
        .collect::<Vec<&ProtoFile>>();

    let structs: Vec<String> = file_proto_infos
        .iter()
        .map(|info| info.structs.clone())
        .flatten()
        .collect();
    let enums: Vec<String> = file_proto_infos
        .iter()
        .map(|info| info.enums.clone())
        .flatten()
        .collect();

    let mut derive_template = ProtobufDeriveMeta::new(structs, enums);
    let new_content = derive_template.render().unwrap();
    let old_content = read_file(derive_meta_dir).unwrap();
    if new_content == old_content {
        return;
    }
    // println!("{}", diff_lines(&old_content, &new_content));
    match OpenOptions::new()
        .create(true)
        .write(true)
        .append(false)
        .truncate(true)
        .open(derive_meta_dir)
    {
        Ok(ref mut file) => {
            file.write_all(new_content.as_bytes()).unwrap();
        }
        Err(err) => {
            panic!("Failed to open log file: {}", err);
        }
    }
}
