#![allow(unused_imports)]
#![allow(unused_attributes)]
#![allow(dead_code)]
mod ast;
mod proto_gen;
mod proto_info;
mod template;

use crate::code_gen::util::path_string_with_component;
use itertools::Itertools;
use log::info;
pub use proto_gen::*;
pub use proto_info::*;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;
use walkdir::WalkDir;

pub fn gen(crate_name: &str) {
    let crate_path = std::fs::canonicalize(".").unwrap().as_path().display().to_string();

    // 1. generate the proto files to proto_file_dir
    #[cfg(feature = "proto_gen")]
    let proto_crates = gen_proto_files(crate_name, &crate_path);

    for proto_crate in proto_crates {
        let mut proto_file_paths = vec![];
        let mut file_names = vec![];
        let proto_file_output_path = proto_crate.proto_output_path().to_str().unwrap().to_string();
        let protobuf_output_path = proto_crate.protobuf_crate_path().to_str().unwrap().to_string();

        for (path, file_name) in WalkDir::new(&proto_file_output_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .map(|e| {
                let path = e.path().to_str().unwrap().to_string();
                let file_name = e.path().file_stem().unwrap().to_str().unwrap().to_string();
                (path, file_name)
            })
        {
            if path.ends_with(".proto") {
                // https://stackoverflow.com/questions/49077147/how-can-i-force-build-rs-to-run-again-without-cleaning-my-whole-project
                println!("cargo:rerun-if-changed={}", path);
                proto_file_paths.push(path);
                file_names.push(file_name);
            }
        }
        let protoc_bin_path = protoc_bin_vendored::protoc_bin_path().unwrap();

        // 2. generate the protobuf files(Dart)
        #[cfg(feature = "dart")]
        generate_dart_protobuf_files(
            crate_name,
            &proto_file_output_path,
            &proto_file_paths,
            &file_names,
            &protoc_bin_path,
        );

        // 3. generate the protobuf files(Rust)
        generate_rust_protobuf_files(
            &protoc_bin_path,
            &proto_file_paths,
            &proto_file_output_path,
            &protobuf_output_path,
        );
    }
}

fn generate_rust_protobuf_files(
    protoc_bin_path: &Path,
    proto_file_paths: &[String],
    proto_file_output_path: &str,
    protobuf_output_path: &str,
) {
    protoc_rust::Codegen::new()
        .out_dir(protobuf_output_path)
        .protoc_path(protoc_bin_path)
        .inputs(proto_file_paths)
        .include(proto_file_output_path)
        .run()
        .expect("Running rust protoc failed.");
}

#[cfg(feature = "dart")]
fn generate_dart_protobuf_files(
    name: &str,
    proto_file_output_path: &str,
    paths: &Vec<String>,
    file_names: &Vec<String>,
    protoc_bin_path: &PathBuf,
) {
    if std::env::var("CARGO_MAKE_WORKING_DIRECTORY").is_err() {
        log::warn!("CARGO_MAKE_WORKING_DIRECTORY was not set, skip generate dart pb");
        return;
    }

    if std::env::var("FLUTTER_FLOWY_SDK_PATH").is_err() {
        log::warn!("FLUTTER_FLOWY_SDK_PATH was not set, skip generate dart pb");
        return;
    }

    let mut output = PathBuf::new();
    output.push(std::env::var("CARGO_MAKE_WORKING_DIRECTORY").unwrap());
    output.push(std::env::var("FLUTTER_FLOWY_SDK_PATH").unwrap());
    output.push("lib");
    output.push("protobuf");
    output.push(name);

    if !output.as_path().exists() {
        std::fs::create_dir_all(&output).unwrap();
    }
    check_pb_dart_plugin();
    let protoc_bin_path = protoc_bin_path.to_str().unwrap().to_owned();
    paths.iter().for_each(|path| {
        let result = cmd_lib::run_cmd! {
            ${protoc_bin_path} --dart_out=${output} --proto_path=${proto_file_output_path} ${path}
        };

        if result.is_err() {
            panic!("Generate dart pb file failed with: {}, {:?}", path, result)
        };
    });

    let protobuf_dart = path_string_with_component(&output, vec!["protobuf.dart"]);

    match std::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .append(false)
        .truncate(true)
        .open(&protobuf_dart)
    {
        Ok(ref mut file) => {
            let mut export = String::new();
            export.push_str("// Auto-generated, do not edit \n");
            for file_name in file_names {
                let c = format!("export './{}.pb.dart';\n", file_name);
                export.push_str(c.as_ref());
            }

            file.write_all(export.as_bytes()).unwrap();
            File::flush(file).unwrap();
        }
        Err(err) => {
            panic!("Failed to open file: {}", err);
        }
    }
}

pub fn check_pb_dart_plugin() {
    if cfg!(target_os = "windows") {
        //Command::new("cmd")
        //    .arg("/C")
        //    .arg(cmd)
        //    .status()
        //    .expect("failed to execute process");
        //panic!("{}", format!("\n❌ The protoc-gen-dart was not installed correctly."))
    } else {
        let exit_result = Command::new("sh")
            .arg("-c")
            .arg("command -v protoc-gen-dart")
            .status()
            .expect("failed to execute process");

        if !exit_result.success() {
            let mut msg = "\n❌ Can't find protoc-gen-dart in $PATH:\n".to_string();
            let output = Command::new("sh").arg("-c").arg("echo $PATH").output();
            let paths = String::from_utf8(output.unwrap().stdout)
                .unwrap()
                .split(':')
                .map(|s| s.to_string())
                .collect::<Vec<String>>();

            paths.iter().for_each(|s| msg.push_str(&format!("{}\n", s)));

            if let Ok(output) = Command::new("sh").arg("-c").arg("which protoc-gen-dart").output() {
                msg.push_str(&format!(
                    "Installed protoc-gen-dart path: {:?}\n",
                    String::from_utf8(output.stdout).unwrap()
                ));
            }

            msg.push_str("✅ You can fix that by adding:");
            msg.push_str("\n\texport PATH=\"$PATH\":\"$HOME/.pub-cache/bin\"\n");
            msg.push_str("to your shell's config file.(.bashrc, .bash, .profile, .zshrc etc.)");
            panic!("{}", msg)
        }
    }
}

#[cfg(feature = "proto_gen")]
fn gen_proto_files(crate_name: &str, crate_path: &str) -> Vec<ProtobufCrate> {
    let crate_context = ProtoGenerator::gen(crate_name, crate_path);
    let proto_crates = crate_context
        .iter()
        .map(|info| info.protobuf_crate.clone())
        .collect::<Vec<_>>();

    crate_context.into_iter().flat_map(|info| info.files).for_each(|file| {
        println!("cargo:rerun-if-changed={}", file.file_path);
    });

    proto_crates
}
