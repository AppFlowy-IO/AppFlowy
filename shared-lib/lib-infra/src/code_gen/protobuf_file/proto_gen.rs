#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::code_gen::protobuf_file::ast::parse_protobuf_context_from;
use crate::code_gen::protobuf_file::proto_info::ProtobufCrateContext;
use crate::code_gen::protobuf_file::ProtoFile;
use crate::code_gen::util::*;
use crate::code_gen::ProtoCache;
use std::fs::File;
use std::path::Path;
use std::{fs::OpenOptions, io::Write};

pub struct ProtoGenerator();
impl ProtoGenerator {
    pub fn gen(crate_name: &str, crate_path: &str) -> Vec<ProtobufCrateContext> {
        let crate_contexts = parse_protobuf_context_from(vec![crate_path.to_owned()]);
        write_proto_files(&crate_contexts);
        write_rust_crate_mod_file(&crate_contexts);

        let proto_cache = ProtoCache::from_crate_contexts(&crate_contexts);
        let proto_cache_str = serde_json::to_string(&proto_cache).unwrap();

        let crate_cache_dir = path_buf_with_component(&cache_dir(), vec![crate_name]);
        if !crate_cache_dir.as_path().exists() {
            std::fs::create_dir_all(&crate_cache_dir).unwrap();
        }

        let protobuf_cache_path = path_string_with_component(&crate_cache_dir, vec!["proto_cache"]);

        match std::fs::OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&protobuf_cache_path)
        {
            Ok(ref mut file) => {
                file.write_all(proto_cache_str.as_bytes()).unwrap();
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
        let dir = context.protobuf_crate.proto_file_output_dir();
        context.files.iter().for_each(|info| {
            let proto_file = format!("{}.proto", &info.file_name);
            let proto_file_path = path_string_with_component(&dir, vec![&proto_file]);
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
                    context.protobuf_crate.proto_file_output_dir(),
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
