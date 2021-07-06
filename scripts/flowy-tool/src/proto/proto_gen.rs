use crate::proto::ast::*;
use crate::proto::helper::*;
use crate::{proto::template::*, util::*};

use std::{fs::OpenOptions, io::Write};

use std::fs::File;
use walkdir::WalkDir;

pub struct ProtoGen {
    pub(crate) rust_source_dir: String,
    pub(crate) flutter_package_lib: String,
    pub(crate) derive_meta_dir: String,
}

impl ProtoGen {
    pub fn gen(&self) {
        let crate_proto_infos = parse_crate_protobuf(self.rust_source_dir.as_ref());
        write_proto_files(&crate_proto_infos);

        run_rust_protoc(&crate_proto_infos);
        write_rust_crate_mod_file(&crate_proto_infos);

        let package_root = self.flutter_package_lib.as_ref();
        let model_dir = format!("{}/protobuf", package_root);
        run_flutter_protoc(&crate_proto_infos, model_dir.as_ref());
        write_flutter_crate_mod_file(package_root, model_dir.as_ref());

        write_derive_meta(&crate_proto_infos, self.derive_meta_dir.as_ref());
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

fn write_rust_crate_mod_file(crate_infos: &Vec<CrateProtoInfo>) {
    for crate_info in crate_infos {
        let mod_path = crate_info.inner.proto_model_mod_file();
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&mod_path)
        {
            Ok(ref mut file) => {
                let mut mod_file_content = String::new();
                mod_file_content.push_str("// Auto-generated, do not edit \n");
                walk_dir(
                    crate_info.inner.proto_file_output_dir().as_ref(),
                    |e| e.file_type().is_dir() == false,
                    |_, name| {
                        let c = format!("\nmod {}; \npub use {}::*; \n", &name, &name);
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

fn write_flutter_crate_mod_file(package_root: &str, model_dir: &str) {
    let mod_path = format!("{}/protobuf.dart", package_root);
    match OpenOptions::new()
        .create(true)
        .write(true)
        .append(false)
        .truncate(true)
        .open(&mod_path)
    {
        Ok(ref mut file) => {
            let mut mod_file_content = String::new();
            mod_file_content.push_str("// Auto-generated, do not edit \n");
            walk_dir(
                model_dir,
                |e| e.file_type().is_dir() == false,
                |_, name| {
                    let c = format!("export 'protobuf/{}.pb.dart';\n", &name);
                    mod_file_content.push_str(c.as_ref());
                },
            );
            file.write_all(mod_file_content.as_bytes()).unwrap();
            file.flush().unwrap();
        }
        Err(err) => {
            panic!("Failed to open file: {}", err);
        }
    }
}

fn run_rust_protoc(crate_infos: &Vec<CrateProtoInfo>) {
    for crate_info in crate_infos {
        let rust_out = crate_info.inner.proto_struct_output_dir();
        let proto_path = crate_info.inner.proto_file_output_dir();
        walk_dir(
            proto_path.as_ref(),
            |e| is_proto_file(e),
            |proto_file, _| {
                if cmd_lib::run_cmd! {
                    protoc --rust_out=${rust_out} --proto_path=${proto_path} ${proto_file}
                }
                .is_err()
                {
                    panic!("Run flutter protoc fail")
                };
            },
        );

        crate_info.create_crate_mod_file();
    }
}

fn run_flutter_protoc(crate_infos: &Vec<CrateProtoInfo>, model_dir: &str) {
    create_dir_if_not_exist(model_dir.as_ref());
    for crate_info in crate_infos {
        let proto_path = crate_info.inner.proto_file_output_dir();
        walk_dir(
            proto_path.as_ref(),
            |e| is_proto_file(e),
            |proto_file, _| {
                if cmd_lib::run_cmd! {
                    protoc --dart_out=${model_dir} --proto_path=${proto_path} ${proto_file}
                }
                .is_err()
                {
                    panic!("Run flutter protoc fail")
                };
            },
        );
    }
}

fn walk_dir<F1, F2>(dir: &str, filter: F2, mut path_and_name: F1)
where
    F1: FnMut(String, String),
    F2: Fn(&walkdir::DirEntry) -> bool,
{
    for (path, name) in WalkDir::new(dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| filter(e))
        .map(|e| {
            (
                e.path().to_str().unwrap().to_string(),
                e.path().file_stem().unwrap().to_str().unwrap().to_string(),
            )
        })
    {
        path_and_name(path, name);
    }
}
