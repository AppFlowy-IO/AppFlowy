#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::proto_gen::ast::parse_crate_protobuf;
use crate::proto_gen::proto_info::ProtobufCrateContext;
use crate::proto_gen::util::*;
use crate::proto_gen::ProtoFile;
use std::fs::File;
use std::path::Path;
use std::{fs::OpenOptions, io::Write};

pub(crate) struct ProtoGenerator();
impl ProtoGenerator {
    pub(crate) fn gen(crate_name: &str, crate_path: &str, cache_path: &str) -> Vec<ProtobufCrateContext> {
        let crate_contexts = parse_crate_protobuf(vec![crate_path.to_owned()]);
        write_proto_files(&crate_contexts);
        write_rust_crate_mod_file(&crate_contexts);
        for crate_info in &crate_contexts {
            let _ = crate_info.protobuf_crate.create_output_dir();
            let _ = crate_info.protobuf_crate.proto_output_dir();
            crate_info.create_crate_mod_file();
        }

        let cache = ProtoCache::from_crate_contexts(&crate_contexts);
        let cache_str = serde_json::to_string(&cache).unwrap();
        let cache_dir = format!("{}/.cache/{}", cache_path, crate_name);
        if !Path::new(&cache_dir).exists() {
            std::fs::create_dir_all(&cache_dir).unwrap();
        }

        let protobuf_cache_path = format!("{}/proto_cache", cache_dir);
        match std::fs::OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&protobuf_cache_path)
        {
            Ok(ref mut file) => {
                file.write_all(cache_str.as_bytes()).unwrap();
                File::flush(file).unwrap();
            }
            Err(_err) => {
                panic!("Failed to open file: {}", protobuf_cache_path);
            }
        }

        crate_contexts
    }
}

fn write_proto_files(crate_contexts: &[ProtobufCrateContext]) {
    for context in crate_contexts {
        let dir = context.protobuf_crate.proto_output_dir();
        context.files.iter().for_each(|info| {
            let proto_file_path = format!("{}/{}.proto", dir, &info.file_name);
            save_content_to_file_with_diff_prompt(&info.generated_content, proto_file_path.as_ref());
        });
    }
}

fn write_rust_crate_mod_file(crate_contexts: &[ProtobufCrateContext]) {
    for context in crate_contexts {
        let mod_path = context.protobuf_crate.proto_model_mod_file();
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&mod_path)
        {
            Ok(ref mut file) => {
                let mut mod_file_content = String::new();

                mod_file_content.push_str("#![cfg_attr(rustfmt, rustfmt::skip)]\n");
                mod_file_content.push_str("// Auto-generated, do not edit\n");
                walk_dir(
                    context.protobuf_crate.proto_output_dir().as_ref(),
                    |e| !e.file_type().is_dir(),
                    |_, name| {
                        let c = format!("\nmod {};\npub use {}::*;\n", &name, &name);
                        mod_file_content.push_str(c.as_ref());
                    },
                );
                file.write_all(mod_file_content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open file: {}", err);
            }
        }
    }
}

#[derive(serde::Serialize, serde::Deserialize)]
pub struct ProtoCache {
    pub structs: Vec<String>,
    pub enums: Vec<String>,
}

impl ProtoCache {
    fn from_crate_contexts(crate_contexts: &[ProtobufCrateContext]) -> Self {
        let proto_files = crate_contexts
            .iter()
            .map(|crate_info| &crate_info.files)
            .flatten()
            .collect::<Vec<&ProtoFile>>();

        let structs: Vec<String> = proto_files.iter().map(|info| info.structs.clone()).flatten().collect();
        let enums: Vec<String> = proto_files.iter().map(|info| info.enums.clone()).flatten().collect();
        Self { structs, enums }
    }
}
