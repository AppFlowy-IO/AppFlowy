use crate::proto::ast::*;
use crate::proto::proto_info::*;
use crate::{proto::template::*, util::*};
use std::path::Path;
use std::{fs::OpenOptions, io::Write};

pub struct ProtoGen {
    pub(crate) rust_source_dir: String,
    pub(crate) flutter_package_lib: String,
    pub(crate) derive_meta_dir: String,
}

impl ProtoGen {
    pub fn gen(&self) {
        let crate_proto_infos = parse_crate_protobuf(self.rust_source_dir.as_ref());
        write_proto_files(&crate_proto_infos);

        // FIXME: ignore unchanged file to reduce time cost
        run_rust_protoc(&crate_proto_infos);
        write_rust_crate_mod_file(&crate_proto_infos);
        write_derive_meta(&crate_proto_infos, self.derive_meta_dir.as_ref());

        // FIXME: ignore unchanged file to reduce time cost
        let flutter_package = FlutterProtobufInfo::new(self.flutter_package_lib.as_ref());
        run_flutter_protoc(&crate_proto_infos, &flutter_package);
        write_flutter_protobuf_package_mod_file(&crate_proto_infos, &flutter_package);
    }
}

fn write_proto_files(crate_infos: &Vec<CrateProtoInfo>) {
    for crate_info in crate_infos {
        let dir = crate_info.inner.proto_file_output_dir();
        remove_everything_in_dir(dir.as_str());
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

fn write_flutter_protobuf_package_mod_file(
    crate_infos: &Vec<CrateProtoInfo>,
    package_info: &FlutterProtobufInfo,
) {
    let mod_path = package_info.mod_file_path();
    let _model_dir = package_info.model_dir();
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

            for crate_info in crate_infos {
                let _mod_path = crate_info.inner.proto_model_mod_file();
                walk_dir(
                    crate_info.inner.proto_file_output_dir().as_ref(),
                    |e| e.file_type().is_dir() == false,
                    |_, name| {
                        let c = format!("export 'protobuf/{}.pb.dart';\n", &name);
                        mod_file_content.push_str(c.as_ref());
                    },
                );
            }

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

fn run_flutter_protoc(crate_infos: &Vec<CrateProtoInfo>, package_info: &FlutterProtobufInfo) {
    let model_dir = package_info.model_dir();
    let removed_dir = format!("{}/", model_dir);
    remove_everything_in_dir(removed_dir.as_str());

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

fn remove_everything_in_dir(dir: &str) {
    if !Path::new(dir).exists() {
        if cmd_lib::run_cmd! {
            rm -rf ${dir}
            mkdir ${dir}
        }
        .is_err()
        {
            panic!("Reset protobuf directory failed")
        };
    } else {
        std::fs::create_dir_all(dir).unwrap();
    }
}
