use crate::proto_gen::ast::parse_crate_protobuf;
use crate::proto_gen::proto_info::ProtobufCrateContext;
use crate::proto_gen::template::write_derive_meta;
use crate::proto_gen::util::*;
use std::{fs::OpenOptions, io::Write};

pub(crate) struct ProtoGenerator();
impl ProtoGenerator {
    pub(crate) fn gen(root: &str) -> Vec<ProtobufCrateContext> {
        let crate_contexts = parse_crate_protobuf(vec![root.to_owned()]);
        write_proto_files(&crate_contexts);
        write_rust_crate_mod_file(&crate_contexts);
        for crate_info in &crate_contexts {
            let _ = crate_info.protobuf_crate.create_output_dir();
            let _ = crate_info.protobuf_crate.proto_output_dir();
            crate_info.create_crate_mod_file();
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
