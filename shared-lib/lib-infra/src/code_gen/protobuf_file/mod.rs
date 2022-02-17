#![allow(unused_imports)]
#![allow(unused_attributes)]
#![allow(dead_code)]
mod ast;
mod proto_gen;
mod proto_info;
mod template;

pub use proto_gen::*;
pub use proto_info::*;

#[cfg(feature = "proto_gen")]
use log::info;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use walkdir::WalkDir;

pub fn gen(crate_name: &str, proto_file_dir: &str) {
    // 1. generate the proto files to proto_file_dir
    #[cfg(feature = "proto_gen")]
    let _ = gen_protos(crate_name);

    let mut proto_file_paths = vec![];
    let mut file_names = vec![];

    for (path, file_name) in WalkDir::new(proto_file_dir)
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
    

    // 3. generate the protobuf files(Rust)
    generate_rust_protobuf_files(&protoc_bin_path, &proto_file_paths, proto_file_dir);
}

fn generate_rust_protobuf_files(protoc_bin_path: &PathBuf, proto_file_paths: &Vec<String>, proto_file_dir: &str) {
    protoc_rust::Codegen::new()
        .out_dir("./src/protobuf/model")
        .protoc_path(protoc_bin_path)
        .inputs(proto_file_paths)
        .include(proto_file_dir)
        .run()
        .expect("Running protoc failed.");
}

#[cfg(feature = "dart")]
fn generate_dart_protobuf_files(
    name: &str,
    root: &str,
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

    let workspace_dir = std::env::var("CARGO_MAKE_WORKING_DIRECTORY").unwrap();
    let flutter_sdk_path = std::env::var("FLUTTER_FLOWY_SDK_PATH").unwrap();
    let output = format!("{}/{}/lib/protobuf/{}", workspace_dir, flutter_sdk_path, name);
    if !std::path::Path::new(&output).exists() {
        std::fs::create_dir_all(&output).unwrap();
    }
    check_pb_dart_plugin();
    let protoc_bin_path = protoc_bin_path.to_str().unwrap().to_owned();
    paths.iter().for_each(|path| {
        if cmd_lib::run_cmd! {
            ${protoc_bin_path} --dart_out=${output} --proto_path=${root} ${path}
        }
        .is_err()
        {
            panic!("Generate dart pb file failed with: {}", path)
        };
    });

    let protobuf_dart = format!("{}/protobuf.dart", output);
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

fn check_pb_dart_plugin() {
    if cfg!(target_os = "windows") {
        //Command::new("cmd")
        //    .arg("/C")
        //    .arg(cmd)
        //    .status()
        //    .expect("failed to execute process");
        //panic!("{}", format!("\n❌ The protoc-gen-dart was not installed correctly."))
        
    } else {
        let is_success = Command::new("sh")
            .arg("-c")
            .arg("command -v protoc-gen-dart")
            .status()
            .expect("failed to execute process")
            .success();

        if !is_success {
            panic!("{}", format!("\n❌ The protoc-gen-dart was not installed correctly. \n✅ You can fix that by adding \"{}\" to your shell's config file.(.bashrc, .bash, etc.)", "dart pub global activate protoc_plugin"))
        }
    }
}

#[cfg(feature = "proto_gen")]
fn gen_protos(crate_name: &str) -> Vec<ProtobufCrate> {
    let crate_path = std::fs::canonicalize(".").unwrap().as_path().display().to_string();
    let crate_context = ProtoGenerator::gen(crate_name, &crate_path);
    let proto_crates = crate_context
        .iter()
        .map(|info| info.protobuf_crate.clone())
        .collect::<Vec<_>>();

    crate_context
        .into_iter()
        .map(|info| info.files)
        .flatten()
        .for_each(|file| {
            println!("cargo:rerun-if-changed={}", file.file_path);
        });

    proto_crates
}
