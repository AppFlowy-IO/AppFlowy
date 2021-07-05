use crate::proto::ast::*;
use crate::proto::helper::*;
use crate::{proto::template::*, util::*};
use flowy_ast::*;
use shell::*;
use std::{fs::OpenOptions, io::Write};
use syn::Item;
use walkdir::WalkDir;

pub struct ProtoGen {
    pub(crate) rust_source_dir: String,
    pub(crate) proto_file_output_dir: String,
    pub(crate) rust_mod_dir: String,
    pub(crate) flutter_mod_dir: String,
    pub(crate) derive_meta_dir: String,
}

impl ProtoGen {
    pub fn gen(&self) {
        let crate_proto_infos = parse_crate_protobuf(self.rust_source_dir.as_ref());

        write_proto_files(&crate_proto_infos);

        run_protoc(&crate_proto_infos);

        write_derive_meta(&crate_proto_infos, self.derive_meta_dir.as_ref());

        write_rust_crate_protobuf(&crate_proto_infos);
    }
}

fn write_proto_files(crate_infos: &Vec<CrateProtoInfo>) {
    for crate_info in crate_infos {
        let dir = crate_info.inner.proto_file_output_dir();
        crate_info.files.iter().for_each(|info| {
            let proto_file_path = format!("{}/{}.proto", dir, &info.file_name);
            save_content_to_file_with_diff_prompt(
                &info.generated_content,
                proto_file_path.as_ref(),
                false,
            );
        });
    }
}

fn write_rust_crate_protobuf(crate_infos: &Vec<CrateProtoInfo>) {
    for crate_info in crate_infos {
        let mod_path = crate_info.inner.crate_mod_file();
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&mod_path)
        {
            Ok(ref mut file) => {
                let mut mod_file_content = String::new();
                for (_, file_name) in WalkDir::new(crate_info.inner.proto_file_output_dir())
                    .into_iter()
                    .filter_map(|e| e.ok())
                    .filter(|e| e.file_type().is_dir() == false)
                    .map(|e| {
                        (
                            e.path().to_str().unwrap().to_string(),
                            e.path().file_stem().unwrap().to_str().unwrap().to_string(),
                        )
                    })
                {
                    let c = format!("\nmod {}; \npub use {}::*; \n", &file_name, &file_name);
                    mod_file_content.push_str(c.as_ref());
                }
                file.write_all(mod_file_content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open file: {}", err);
            }
        }
    }
}

fn run_protoc(crate_infos: &Vec<CrateProtoInfo>) {
    // protoc --rust_out=${CARGO_MAKE_WORKSPACE_WORKING_DIRECTORY}/rust-lib/flowy-protobuf/src/model \
    // --proto_path=${CARGO_MAKE_WORKSPACE_WORKING_DIRECTORY}/rust-lib/flowy-protobuf/define \
    // ${CARGO_MAKE_WORKSPACE_WORKING_DIRECTORY}/rust-lib/flowy-protobuf/define/*.proto

    for crate_info in crate_infos {
        let rust_out = crate_info.inner.proto_struct_output_dir();
        let proto_path = crate_info.inner.proto_file_output_dir();

        for proto_file in WalkDir::new(&proto_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| is_proto_file(e))
            .map(|e| e.path().to_str().unwrap().to_string())
        {
            cmd_lib::run_cmd! {
                protoc --rust_out=${rust_out} --proto_path=${proto_path} ${proto_file}
            };
        }
    }
}
